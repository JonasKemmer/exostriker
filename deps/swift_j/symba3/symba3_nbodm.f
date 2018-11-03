c*************************************************************************
c                            SYMBA3_NBODM.F
c*************************************************************************
c Returns the location of the last massive body in the list
c
c             Input:
c                 nbod          ==>  number of massive bodies (int scalar)
c                 mass          ==>  mass of bodies (real array)
c             Output:
c                 nbodm         ==>  location of the last massive body 
c                                    (int scalar)
c
c Remarks:  If all the objects are massive, then nbodm=nbod-1 so that
c           the do loops will have the correct limits.
c Authors:  Hal Levison
c Date:    3/20/97
c Last revision: 3/25/97

      subroutine  symba3_nbodm(nbod,mass,nbodm)

      include '../swift.inc'
      include 'symba3.inc'

c...  Inputs Only: 
      integer nbod
      real*8 mass(nbod)

c...  Outputs only
      integer nbodm

c...  Internals
      integer i

c----
c...  Executable code 

      if(mass(nbod).gt.TINY) then
         nbodm = nbod - 1
         write(*,*) '    Of ',nbod,' objects, all are massive. '
      else
         do i=2,nbod-1
            if(mass(i).gt.TINY) then
               nbodm = i
            endif
         enddo
         write(*,*) '    Of ',nbod,' objects, ',nbodm,' are massive. '
      endif

      return
      end             ! symba3_nbodm.f
c--------------------------------------------------------

