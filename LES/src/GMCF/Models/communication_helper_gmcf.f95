module communication_helper_gmcf
use communication_common
use gmcfAPI
implicit none

integer :: mpi_size ! Names for compatability with existing MPI code

contains

subroutine initialise_gmcf(sys, tile, model_id, procPerRow, procPerCol)
    implicit none
    integer(8) , intent(In) :: sys
    integer(8) , intent(In) :: tile
    integer , intent(In) :: model_id, procPerRow, procPerCol
    mpi_size = procPerRow * procPerCol
    call gmcfInitCoupler(sys, tile, model_id)
end subroutine initialise_gmcf

subroutine finalise_gmcf(model_id)
    implicit none
    integer, intent(in) :: model_id
    call gmcfFinished(model_id)
end subroutine finalise_gmcf

subroutine sendHaloBoundaries(leftSend, rightSend, topSend, bottomSend, model_id, procPerRow, procPerCol)
    implicit none
    real(kind=4), dimension(:,:,:), intent(in) :: leftSend, rightSend, topSend, bottomSend
    integer, intent(in) :: model_id, procPerRow, procPerCol
    integer :: has_packets, fifo_empty
    type(gmcfPacket) :: packet
    !print*, 'Model_id ', model_id, ' is waiting for halo boundary requests'
    if (.not. isTopRow(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for a request from ', model_id - procPerRow
        call gmcfWaitFor(model_id, REQDATA, model_id - procPerRow, 1)
    end if
    if (.not. isBottomRow(model_id, procPerRow, procPerCol)) then
        !print*, 'Model_id ', model_id, ' is waiting for a request from ', model_id + procPerRow
        call gmcfWaitFor(model_id, REQDATA, model_id + procPerRow, 1)
    end if
    if (.not. isLeftmostColumn(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for a request from ', model_id - 1
        call gmcfWaitFor(model_id, REQDATA, model_id - 1, 1)
    end if
    if (.not. isRightmostColumn(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for a request from ', model_id + 1
        call gmcfWaitFor(model_id, REQDATA, model_id + 1, 1)
    end if
    !print*, 'Model_id ', model_id, ' has received halo boundary requests'
    call gmcfHasPackets(model_id, REQDATA, has_packets)
    do while (has_packets == 1)
        call gmcfShiftPending(model_id, REQDATA, packet, fifo_empty)
        select case (packet%data_id)
            case (topTag)
                call gmcfSend3DFloatArray(model_id, topSend, shape(topSend), topTag, packet%source, PRE, 1)
            case (bottomTag)
                call gmcfSend3DFloatArray(model_id, bottomSend, shape(bottomSend), bottomTag, packet%source, PRE, 1)
            case (leftTag)
                call gmcfSend3DFloatArray(model_id, leftSend, shape(leftSend), leftTag, packet%source, PRE, 1)
            case (rightTag)
                call gmcfSend3DFloatArray(model_id, rightSend, shape(rightSend), rightTag, packet%source, PRE, 1)
            case default
                print*, 'Model_id  ', model_id, ' received an unexpected REQDATA.'
        end select
        call gmcfHasPackets(model_id, REQDATA, has_packets)
    end do
    !print*, 'Model_id ', model_id, ' has responded to halo boundary requests'
end subroutine sendHaloBoundaries

subroutine recvHaloBoundaries(leftRecv, rightRecv, topRecv, bottomRecv, model_id, procPerRow, procPerCol)
    implicit none
    real(kind=4), dimension(:,:,:), intent(out) :: leftRecv, rightRecv, topRecv, bottomRecv
    integer, intent(in) :: model_id, procPerRow, procPerCol
    integer :: has_packets, fifo_empty
    type(gmcfPacket) :: packet
    !print*, 'Model_id ', model_id, ' is waiting for halo boundaries'
    if (.not. isTopRow(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for a response from ', model_id - procPerRow
        call gmcfWaitFor(model_id, RESPDATA, model_id - procPerRow, 1)
    end if
    if (.not. isBottomRow(model_id, procPerRow, procPerCol)) then
        !print*, 'Model_id ', model_id, ' is waiting for a response from ', model_id + procPerRow
        call gmcfWaitFor(model_id, RESPDATA, model_id + procPerRow, 1)
    end if
    if (.not. isLeftmostColumn(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for a response from ', model_id - 1
        call gmcfWaitFor(model_id, RESPDATA, model_id - 1, 1)
    end if
    if (.not. isRightmostColumn(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for a response from ', model_id + 1
        call gmcfWaitFor(model_id, RESPDATA, model_id + 1, 1)
    end if
    !print*, 'Model_id ', model_id, ' has finished waiting for halo boundaries'
    call gmcfHasPackets(model_id, RESPDATA, has_packets)
    do while (has_packets == 1)
        call gmcfShiftPending(model_id, RESPDATA, packet, fifo_empty)
        select case (packet%data_id)
            case (topTag)
                call gmcfRead3DFloatArray(topRecv, shape(topRecv), packet)
            case (bottomTag)
                call gmcfRead3DFloatArray(bottomRecv, shape(bottomRecv), packet)
            case (leftTag)
                call gmcfRead3DFloatArray(leftRecv, shape(leftRecv), packet)
            case (rightTag)
                call gmcfRead3DFloatArray(rightRecv, shape(rightRecv), packet)
            case default
                print*, 'Model_id  ', model_id, ' received an unexpected RESPDATA.'
        end select
        call gmcfHasPackets(model_id, RESPDATA, has_packets)
    end do
    !print*, 'Model_id ', model_id, ' has received halo boundaries'
end subroutine recvHaloBoundaries

subroutine waitForHaloAcks(model_id, procPerRow, procPerCol)
    implicit none
    integer, intent(in) :: model_id, procPerRow, procPerCol
    integer :: has_packets, fifo_empty
    type(gmcfPacket) :: packet
    if (.not. isTopRow(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for an ack from ', model_id - procPerRow
        call gmcfWaitFor(model_id, ACKDATA, model_id - procPerRow, 1)
    end if
    if (.not. isBottomRow(model_id, procPerRow, procPerCol)) then
        !print*, 'Model_id ', model_id, ' is waiting for an ack from ', model_id + procPerRow
        call gmcfWaitFor(model_id, ACKDATA, model_id + procPerRow, 1)
    end if
    if (.not. isLeftmostColumn(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for an ack from ', model_id - 1
        call gmcfWaitFor(model_id, ACKDATA, model_id - 1, 1)
    end if
    if (.not. isRightmostColumn(model_id, procPerRow)) then
        !print*, 'Model_id ', model_id, ' is waiting for an ack from ', model_id + 1
        call gmcfWaitFor(model_id, ACKDATA, model_id + 1, 1)
    end if
    call gmcfHasPackets(model_id, ACKDATA, has_packets)
    do while (has_packets == 1)
        call gmcfShiftPending(model_id, ACKDATA, packet, fifo_empty)
        if (packet%source .ne. model_id - procPerRow .and. &
              packet%source .ne. model_id + procPerRow .and. &
              packet%source .ne. model_id - 1 .and. &
              packet%source .ne. model_id + 1) then
            print*, 'Model_id  ', model_id, ' received an unexpected ACKDATA.'
        end if
        call gmcfHasPackets(model_id, RESPDATA, has_packets)
    end do
end subroutine waitForHaloAcks

logical function isMaster(model_id)
    implicit none
    integer, intent(in) :: model_id
    isMaster = model_id .eq. 1
end function isMaster

logical function isTopRow(model_id, procPerRow)
    implicit none
    integer, intent(in) :: model_id, procPerRow
    isTopRow = model_id .le. procPerRow
end function isTopRow

logical function isBottomRow(model_id, procPerRow, procPerCol)
    implicit none
    integer, intent(in) :: model_id, procPerRow, procPerCol
    integer :: instanceCount
    instanceCount = procPerRow * procPerCol
    isBottomRow = model_id .gt. (instanceCount - procPerRow)
end function isBottomRow

logical function isLeftmostColumn(model_id, procPerRow)
    implicit none
    integer, intent(in) :: model_id, procPerRow
    isLeftmostColumn = modulo(model_id - 1, procPerRow) .eq. 0
end function isLeftmostColumn

logical function isRightmostColumn(model_id, procPerRow)
    implicit none
    integer, intent(in) :: model_id, procPerRow
    isRightmostColumn = modulo(model_id - 1, procPerRow) .eq. (procPerRow - 1)
end function isRightmostColumn

integer function topLeftRowValue(process, procPerRow, rowCount)
    implicit none
    integer, intent(in) :: process, procPerRow, rowCount
    topLeftRowValue = process / procPerRow * rowCount
end function topLeftRowValue

integer function topLeftColValue(process, procPerRow, colCount)
    implicit none
    integer, intent(in) :: process, procPerRow, colCount
    topLeftColValue = modulo(process, procPerRow) * colCount
end function topLeftColValue

end module communication_helper_gmcf
