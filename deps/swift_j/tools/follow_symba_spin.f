c converts binary file to ascii file

	include 'swift.inc'

	real*8 mass(NTPMAX),dr
	real*8 xh(NTPMAX),yh(NTPMAX),zh(NTPMAX)
	real*8 vxh(NTPMAX),vyh(NTPMAX),vzh(NTPMAX)

	integer nbodm,nbod,nbod0,ierr,ifol,istep
	integer iflgchk,iu,i,id,nleft,ium
        integer io_read_hdr,io_read_line,io_read_mass,io_read_spin
        integer io_read_hdr_r,io_read_line_r

	real*8 t0,tstop,dt,dtout,dtdump
	real*8 t,tmax

	real*8 rmin,rmax,rmaxu,qmin,rpl(NTPMAX),rhill(NTPMAX)
        logical*2 lclose
        real*8 a,e,inc,capom,omega,capm,j2rp2,j4rp4
        real*8 peri,apo,tg

        real*8 sx(NTPMAX),sy(NTPMAX),sz(NTPMAX),ds(NTPMAX)
	real*8 s2,s,sl,sm,sn,epsilon,lambda,epsilon2,fac
	real*8 sininc,cosinc,sincapom,coscapom
        integer ius,j

        integer plist(NTPMAX),ifoln

	character*80 outfile,inparfile,inplfile,fopenstat

c Get data for the run and the test particles
	write(*,*) 'Enter name of parameter data file : '
	read(*,999) inparfile
	call io_init_param(inparfile,t0,tstop,dt,dtout,dtdump,
     &         iflgchk,rmin,rmax,rmaxu,qmin,lclose,outfile,fopenstat)

c Prompt and read name of planet data file
	write(*,*) ' '
	write(*,*) 'Enter name of planet data file : '
	read(*,999) inplfile
999 	format(a)
	call io_init_pl_symba(inplfile,lclose,iflgchk,nbod,mass,xh,yh,zh,
     &       vxh,vyh,vzh,rpl,rhill,j2rp2,j4rp4)

        iu = 20
        ium = 30
	ius = 90

        dr = 180.0/PI

        if(btest(iflgchk,0)) then
           write(*,*) ' Reading an integer*2 binary file '
        else if(btest(iflgchk,1)) then
           write(*,*) ' Reading an real*4 binary file '
        else
           write(*,*) ' ERROR: no binary file format specified '
           write(*,*) '        in param file '
           stop
        endif

        write(*,*) ' Input the particle number to follow '
        read(*,*) ifol
        ifol = abs(ifol)
        write(*,*) ' Following particle ',ifol

        open(unit=iu, file=outfile, status='old',form='unformatted')
        open(unit=ium, file='mass.'//outfile, status='old',
     *       form='unformatted')
        open(unit=ius, file='spin.'//outfile, status='old',
     *       form='unformatted')
        open(unit=7,file='follow_symba_spin.out')

        nbod0 = nbod
        do i=1,nbod
           plist(i) = i
        enddo
        call follow_plist(0,ifol,ifoln,plist,nbod0,tg,tstop)

        ifoln = ifol

        write(*,*) '1  2 3 4  5    6     7    8    9   10  11 '
        write(*,*) 't,id,a,e,inc,capom,omega,capm,peri,apo, M '

        tmax = t0
 1      continue
             if(btest(iflgchk,0))  then ! bit 0 is set
                ierr = io_read_hdr(iu,t,nbod,nleft) 
             else
                ierr = io_read_hdr_r(iu,t,nbod,nleft) 
             endif
             if(ierr.ne.0) goto 2

             ierr = io_read_mass(t,nbodm,mass,ium)

             ierr = io_read_spin(t,nbodm,sx,sy,sz,ds,ius)

             if(nbodm.ne.nbod) then
                write(*,*) ' Error 1:',nbod,nbodm
                stop
             endif

              do while(t.ge.tg)
                call follow_plist(1,ifol,ifoln,plist,nbod0,
     &               tg,tstop)
             enddo

             istep = 0
             do i=2,nbod
                if(btest(iflgchk,0))  then ! bit 0 is set
                   ierr = io_read_line(iu,id,a,e,inc,capom,omega,capm) 
                else
                   ierr = io_read_line_r(iu,id,a,e,inc,capom,omega,capm) 
                endif
                if(ierr.ne.0) goto 2

                if(abs(id).eq.ifoln) then
		   sininc = sin(inc)
		   cosinc = cos(inc)
		   sincapom = sin(capom)
		   coscapom = cos(capom)

		   j = abs(id)
		   s2 = sx(j)*sx(j) + sy(j)*sy(j) + sz(j)*sz(j)
		   s = dsqrt(s2)
		   sl = coscapom*sx(j) + sincapom*sy(j)
		   sm = cosinc*(-sincapom*sx(j) + coscapom*sy(j)) +
     &                  sininc*sz(j)
		   sn = sininc*( sincapom*sx(j) - coscapom*sy(j)) +
     &                  cosinc*sz(j)
		   epsilon = acos(sn/s)
		   epsilon2 = acos(sz(j)/s)
		   fac = (sl**2 + sm**2)/s2
		   if (fac.lt.TINY) then
		      lambda = 0.d0
		   else
		      lambda = atan2(sm,sl)
		   endif
		   if (lambda.lt.0.d0) lambda = lambda + 2.d0*PI

                   istep = 1
                   inc = inc*dr
                   capom = capom*dr
                   omega = omega*dr
                   capm = capm*dr
                   peri = a*(1.0d0-e)
                   apo = a*(1.0d0+e)
		   epsilon = epsilon*dr
		   lambda = lambda*dr
		   epsilon2 = epsilon2*dr

                   write(7,1000) t,ifoln,a,e,inc,capom,omega,capm,
     &                  peri,apo,mass(j)/mass(1),epsilon,lambda,
     &                  epsilon2,ds(j)
 1000              format(1x,e15.7,1x,i3,1x,e13.5,1x,f7.5,4(1x,f9.4),
     &                  2(1x,e13.5),1e13.5,3(1x,f9.4),1x,e13.5)
                   tmax = t
                endif
             enddo

             if(istep.eq.0) goto 2     ! did not find particle this times step

        goto 1

 2      continue

        write(*,*) ' Tmax = ',tmax

        stop
        end
c-------------------------------------------
        subroutine follow_plist(iflg,ifol,ifoln,plist,nbod,tg,tstop)

	include 'swift.inc'
        real*8 tg,tstop
	integer nbod
        integer iflg,ifol,ifoln,plist(nbod),iwhy
        integer ig,im,idum,i,ierr
        save iwhy

        if(iflg.eq.0) then
           open(2,file='discard_mass.out',status='old',iostat=ierr)
           if(ierr.ne.0) then
              write(*,*) 'Could not open discard_mass.out'
              tg = 5.0*tstop
              return            ! <====== NOTE 
           endif
           read(2,*,iostat=ierr) tg,iwhy
           if(ierr.ne.0) then
              write(*,*) 'Could not read discard_mass.out'
              tg = 5.0*tstop
              return            ! <====== NOTE 
           endif
           ifoln = ifol
           return               ! <====== NOTE 
        endif

        if(iwhy.eq.2) then
           read(2,*) idum,im
           read(2,fmt='(1x)')
           read(2,fmt='(1x)')
           read(2,*) idum,ig
           call left_reorder(ig,im,nbod,plist)
           do i=1,5
              read(2,fmt='(1x)')
           enddo
        else
           read(2,*) idum,ig
           im = -1
           call left_reorder(ig,im,nbod,plist)
           read(2,fmt='(1x)')
           read(2,fmt='(1x)')
        endif

        read(2,*,iostat=ierr) tg,iwhy
        if(ierr.ne.0) then
           tg = 5.0 * tstop
        endif

        ifoln = plist(ifol)

        return
        end

c---------------------------------------------------------------------
       subroutine left_reorder(ig,im,nbod,plist)

       include 'swift.inc'

       integer ig,nbod,plist(nbod),im,i

       do i=1,nbod
          if(plist(i).eq.ig) then
             if(im.gt.0) then
                plist(i) = im
             else
                plist(i) = -1
             endif
          endif
       enddo

       do i=1,nbod
          if(plist(i).gt.ig) then
             plist(i) = plist(i) - 1
          endif
       enddo

       return
       end

c*************************************************************************
c                            IO_READ_SPIN
c*************************************************************************
c read in the spin file.
c
c             Output:
c                 time          ==>  current time (real scalar)
c                 nbod          ==>  number of massive bodies (int scalar)
c                 sx,sy,sz      ==>  vector of spin direction (real arrays)
c                 ds            ==>  error in spin vector (real array)
c                 iu              ==> unit number to read to
c
c             Returns:
c               io_read_spin     ==>   =0 read ok
c                                    !=0 read failed is set to iostat variable
c
c Remarks: Based on io_read_frame
c Authors:  Hal Levison 
c Date:    1/9/97
c Last revision: 7/22/06 MHL

      integer function io_read_spin(time,nbod,sx,sy,sz,ds,iu)

      include 'swift.inc'
      include '../io/io.inc'

c...  Inputs: 
      integer iu

c...  Outputs
      integer nbod
      real*8 sx(nbod),sy(nbod),sz(nbod),ds(nbod),time

c...  Internals
      real*4 sx4(NTPMAX),sy4(NTPMAX),sz4(NTPMAX),ds4(NTPMAX)
      real*4 ttmp
      integer*2 nbod2
      integer i,ierr

c----
c...  Executable code 

      read(iu,iostat=ierr) ttmp,nbod2
      io_read_spin = ierr
      if(ierr.ne.0) then
         return
      endif

      read(iu,iostat=ierr) (sx4(i),sy4(i),sz4(i),ds4(i),i=1,nbod2)
      io_read_spin = ierr
      if(ierr.ne.0) then
         return
      endif

      do i=1,nbod
         sx(i) = sx4(i)
         sy(i) = sy4(i)
         sz(i) = sz4(i)
         ds(i) = ds4(i)
      enddo
      nbod = nbod2
      time = ttmp

      return
      end      ! io_read_spin
c----------------------------------------------------------------------
