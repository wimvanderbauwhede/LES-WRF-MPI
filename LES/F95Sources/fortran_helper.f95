module fortran_helper
implicit none

contains

subroutine outputArray(array)
    implicit none
    integer, dimension(:,:), intent(in) :: array
    integer :: col, row
    do row = 1, size(array, 1)
        do col = 1, size(array,2)
            if (array(row, col) .ne. -1) then
                write(*,"(I4)",advance="no") array(row,col)
            else
                write(*,"(A4)",advance="no") '-'
            end if
        end do
        write (*,*)
    end do
    write (*,*)
end subroutine outputArray

subroutine outputArrayReal(array)
    implicit none
    real(kind=4), dimension(:,:), intent(in) :: array
    integer :: col, row
    do row = 1, size(array, 1)
        do col = 1, size(array,2)
            if (array(row, col) .ne. -1.0) then
                write(*,"(F6.2)",advance="no") array(row,col)
            else
                write(*,"(A6)", advance="no") '-'
            end if
        end do
        write (*,*)
    end do
    write (*,*)
end subroutine outputArrayReal

end module fortran_helper
