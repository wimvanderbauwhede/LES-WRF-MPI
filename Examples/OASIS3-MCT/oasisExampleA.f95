program oasisExampleA
use netcdf
use mod_oasis
use oasisHelpers
implicit none

character(len=6), parameter :: componentName = "A"
character(len=8), parameter :: componentOutField = "outField"
integer, parameter :: timeStep = 3600

call main()

contains

subroutine main()
    implicit none
    integer :: componentId, communicatorId, ierror
    integer :: componentProcessCount, componentProcessId
    call oasis_init_comp(componentId, componentName, ierror)
    call checkIError(ierror, componentId, componentName)
    call oasis_get_localcomm(communicatorId, ierror)
    call checkIError(ierror, componentId, componentName)
    call MPI_Comm_Size(communicatorId, componentProcessCount, ierror)
    call checkIError(ierror, componentId, componentName)
    call MPI_Comm_Rank(communicatorId, componentProcessId, ierror)
    call oasis_terminate(ierror)
    call checkIError(ierror, componentId, componentName)
end subroutine main

end program oasisExampleA

