!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine summary
  !-----------------------------------------------------------------------
  !
  !    This routine writes on output all the information obtained from
  !    the input file and from the setup routine, before starting the
  !    self-consistent calculation.
  !
  !    if iverbosity = 0 only a partial summary is done.
  !
#include "machine.h"
  use pwcom
  use funct
  implicit none
  !
  !     declaration of the local variables
  !
  integer :: i, ipol, apol, na, isym, ik, ib, nt, l, ngmtot
  ! counter on the celldm elements
  ! counter on polarizations
  ! counter on direct or reciprocal lattice vect
  ! counter on atoms
  ! counter on symmetries
  ! counter on k points
  ! counter on beta functions
  ! counter on types
  ! counter on angular momenta
  ! total number of G-vectors (parallel executio
  real(kind=DP) :: sr (3, 3), ft1, ft2, ft3
  ! symmetry matrix in real axes
  ! fractionary translation
  real(kind=DP), allocatable :: xau (:,:)
  ! atomic coordinate referred to the crystal axes
  real(kind=DP) :: xkg (3)
  ! coordinates of the k point in crystal axes
  character :: mixing_style * 9
  character :: ps * 5
  ! name of pseudo type
  real(kind=DP) :: xp
  ! fraction contributing to a given atom type (obsolescent)
  !
  !     we start with a general description of the run
  !
  if (imix.eq.-1) mixing_style = 'potential'
  if (imix.eq. 0) mixing_style = 'plain'
  if (imix.eq. 1) mixing_style = 'TF'
  if (imix.eq. 2) mixing_style = 'local-TF'

  if (title.ne.' ') then
     write (6,"(/,5x,'Title: ',/,5x,a75)") title
  end if
  write (6, 100) ibrav, alat, omega, nat, ntyp, &
       ecutwfc, dual * ecutwfc, tr2, mixing_beta, nmix, &
       mixing_style

100 format (/,/,5x, &
       &     'bravais-lattice index     = ',i12,/,5x, &
       &     'lattice parameter (a_0)   = ',f12.4,'  a.u.',/,5x, &
       &     'unit-cell volume          = ',f12.4,' (a.u.)^3',/,5x, &
       &     'number of atoms/cell      = ',i12,/,5x, &
       &     'number of atomic types    = ',i12,/,5x, &
       &     'kinetic-energy cutoff     = ',f12.4,'  Ry',/,5x, &
       &     'charge density cutoff     = ',f12.4,'  Ry',/,5x, &
       &     'convergence threshold     = ',1pe12.1,/,5x, &
       &     'beta                      = ',0pf12.4,/,5x, &
       &     'number of iterations used = ',i12,2x,a,' mixing')
  write (6, '(5x,"Exchange-correlation      = ",a, &
       &       " (",4i1,")")') trim(dft) , iexch, icorr, igcx, igcc
  if (iswitch.gt.0) then
     write (6, '(5x,"iswitch = ",i2,"  nstep  = ",i4,/)') iswitch, nstep
  else
     write (6, '(5x,"iswitch = ",i2/)') iswitch
  endif

  if (qcutz.gt.0.d0) then
     write (6, 110) ecfixed, qcutz, q2sigma
110  format   (5x,'A smooth kinetic-energy cutoff is imposed at ', &
          &             f12.4,' Ry',/5x,'height of the smooth ', &
          &             'step-function =',f21.4,' Ry',/5x, &
          &             'width of the smooth step-function  =',f21.4, &
          &             ' Ry',/)

  endif
  !
  !    and here more detailed information. Description of the unit cell
  !
  write (6, '(2(3x,3(2x,"celldm(",i1,")=",f11.5),/))') (i, celldm(i), i=1,6)
  write (6, '(5x, &
       &     "crystal axes: (cart. coord. in units of a_0)",/, &
       &       3(15x,"a(",i1,") = (",3f8.4," )  ",/ ) )')  (apol,  &
       (at (ipol, apol) , ipol = 1, 3) , apol = 1, 3)

  write (6, '(5x, &
       &   "reciprocal axes: (cart. coord. in units 2 pi/a_0)",/, &
       &            3(15x,"b(",i1,") = (",3f8.4," )  ",/ ) )')  (apol,&
       &  (bg (ipol, apol) , ipol = 1, 3) , apol = 1, 3)
  do nt = 1, ntyp
     if (tvanp (nt) ) then
        ps = '(US)'
        write (6, '(/5x,"PSEUDO",i2," is ",a2, &
             &        1x,a5,"   zval =",f5.1,"   lmax=",i2, &
             &        "   lloc=",i2)') nt, psd (nt) , ps, zp (nt) , lmax (nt) &
             &, lloc (nt)
        write (6, '(5x,"Version ", 3i3, " of US pseudo code")') &
             (iver (i, nt) , i = 1, 3)
        write (6, '(5x,"Using log mesh of ", i5, " points")') mesh (nt)
        write (6, '(5x,"The pseudopotential has ",i2, &
             &       " beta functions with: ")') nbeta (nt)
        do ib = 1, nbeta (nt)
           write (6, '(15x," l(",i1,") = ",i3)') ib, lll (ib, nt)

        enddo
        write (6, '(5x,"Q(r) pseudized with ", &
             &          i2," coefficients,  rinner = ",3f8.3,/ &
             &          58x,2f8.3)') nqf(nt), (rinner(i,nt), i=1,nqlc(nt) )
     else
        if (nlc (nt) .eq.1.and.nnl (nt) .eq.1) then
           ps = '(vbc)'
        elseif (nlc (nt) .eq.2.and.nnl (nt) .eq.3) then
           ps = '(bhs)'
        elseif (nlc (nt) .eq.1.and.nnl (nt) .eq.3) then
           ps = '(our)'
        else
           ps = '     '
        endif

        write (6, '(/5x,"PSEUDO",i2," is ",a2, 1x,a5,"   zval =",f5.1,&
             &      "   lmax=",i2,"   lloc=",i2)') &
                        nt, psd(nt), ps, zp(nt), lmax(nt), lloc(nt)
        if (numeric (nt) ) then
           write (6, '(5x,"(in numerical form: ",i5,&
                &" grid points",", xmin = ",f5.2,", dx = ",f6.4,")")')&
                & mesh (nt) , xmin (nt) , dx (nt)
        else
           write (6, '(/14x,"i=",7x,"1",13x,"2",10x,"3")')
           write (6, '(/5x,"core")')
           write (6, '(5x,"alpha =",4x,3g13.5)') (alpc (i, nt) , i = 1, 2)
           write (6, '(5x,"a(i)  =",4x,3g13.5)') (cc (i, nt) , i = 1, 2)
           do l = 0, lmax (nt)
              write (6, '(/5x,"l = ",i2)') l
              write (6, '(5x,"alpha =",4x,3g13.5)') (alps (i, l, nt) , &
                   i = 1, 3)
              write (6, '(5x,"a(i)  =",4x,3g13.5)') (aps (i, l, nt) , i = 1,3)
              write (6, '(5x,"a(i+3)=",4x,3g13.5)') (aps (i, l, nt) , i= 4, 6)
           enddo
           if ( nlcc(nt) ) write(6, 200) a_nlcc(nt), b_nlcc(nt), alpha_nlcc(nt)
200        format(/5x,'nonlinear core correction: ', &
                &     'rho(r) = ( a + b r^2) exp(-alpha r^2)', &
                & /,5x,'a    =',4x,g11.5, &
                & /,5x,'b    =',4x,g11.5, &
                & /,5x,'alpha=',4x,g11.5)
        endif
     endif

  enddo
  write (6, '(/5x, "atomic species   valence    mass     pseudopotential")')
  xp = 1.d0
  do nt = 1, ntyp
     if (calc.eq.' ') then
        write (6, '(5x,a6,6x,f10.2,2x,f10.5,5x,5 (a2,"(",f5.2,")"))') &
                   atm(nt), zv(nt), amass(nt), psd(nt), xp
     else
        write (6, '(5x,a6,6x,f10.2,2x,f10.5,5x,5 (a2,"(",f5.2,")"))') &
                   atm(nt), zv(nt), amass(nt)/amconv, psd(nt), xp
     end if
  enddo

  if (calc.eq.'cd' .or. calc.eq.'cm' ) &
     write (6, '(/5x," cell mass =", f10.5, " UMA ")') cmass/amconv
  if (calc.eq.'nd' .or. calc.eq.'nm' ) &
     write (6, '(/5x," cell mass =", f10.5, " UMA/(a.u.)^2 ")') cmass/amconv

  if (lsda) then
     write (6, '(/5x,"Starting magnetic structure ", &
          &      /5x,"atomic species   magnetization")')
     do nt = 1, ntyp
        write (6, '(5x,a6,9x,f6.3)') atm(nt), starting_magnetization(nt)
     enddo
  endif
  !
  !   description of symmetries
  !
  if (nsym.le.1) then
     write (6, '(/5x,"No symmetry!")')
  else
     if (invsym) then
        write (6, '(/5x,i2," Sym.Ops. (with inversion)",/)') nsym
     else
        write (6, '(/5x,i2," Sym.Ops. (no inversion)",/)') nsym
     endif
  endif
  if (iverbosity.eq.1) then
     write (6, '(36x,"s",24x,"frac. trans.")')
     do isym = 1, nsym
        write (6, '(/6x,"isym = ",i2,5x,a45/)') isym, sname(isym)
        call s_axis_to_cart (s(1,1,isym), sr, at, bg)
        if (ftau(1,isym).ne.0.or.ftau(2,isym).ne.0.or.ftau(3,isym).ne.0) then
           ft1 = at(1,1)*ftau(1,isym)/nr1 + at(1,2)*ftau(2,isym)/nr2 + &
                 at(1,3)*ftau(3,isym)/nr3
           ft2 = at(2,1)*ftau(1,isym)/nr1 + at(2,2)*ftau(2,isym)/nr2 + &
                 at(2,3)*ftau(3,isym)/nr3
           ft3 = at(3,1)*ftau(1,isym)/nr1 + at(3,2)*ftau(2,isym)/nr2 + &
                 at(3,3)*ftau(3,isym)/nr3
           write (6, '(1x,"cryst.",3x,"s(",i2,") = (",3(i6,5x), &
                 &        " )    f =( ",f10.7," )")') &
                 isym, (s(1,ipol,isym),ipol=1,3), float(ftau(1,isym))/float(nr1)
           write (6, '(17x," (",3(i6,5x), " )       ( ",f10.7," )")') &
                       (s(2,ipol,isym),ipol=1,3), float(ftau(2,isym))/float(nr2)
           write (6, '(17x," (",3(i6,5x), " )       ( ",f10.7," )"/)') &
                       (s(3,ipol,isym),ipol=1,3), float(ftau(3,isym))/float(nr3)
           write (6, '(1x,"cart. ",3x,"s(",i2,") = (",3f11.7, &
                 &        " )    f =( ",f10.7," )")') &
                 isym, (sr(1,ipol),ipol=1,3), ft1
           write (6, '(17x," (",3f11.7, " )       ( ",f10.7," )")') &
                       (sr(2,ipol),ipol=1,3), ft2
           write (6, '(17x," (",3f11.7, " )       ( ",f10.7," )"/)') &
                       (sr(3,ipol),ipol=1,3), ft3
        else
           write (6, '(1x,"cryst.",3x,"s(",i2,") = (",3(i6,5x), " )")') &
                                     isym,  (s (1, ipol, isym) , ipol = 1,3)
           write (6, '(17x," (",3(i6,5x)," )")')  (s(2,ipol,isym), ipol=1,3)
           write (6, '(17x," (",3(i6,5x)," )"/)') (s(3,ipol,isym), ipol=1,3)
           write (6, '(1x,"cart. ",3x,"s(",i2,") = (",3f11.7," )")') &
                                         isym,  (sr (1, ipol) , ipol = 1, 3)
           write (6, '(17x," (",3f11.7," )")')  (sr (2, ipol) , ipol = 1, 3)
           write (6, '(17x," (",3f11.7," )"/)') (sr (3, ipol) , ipol = 1, 3)
        endif
     enddo

  endif
  !
  !    description of the atoms inside the unit cell
  !
  write (6, '(/,3x,"Cartesian axes")')
  write (6, '(/,5x,"site n.     atom                  positions (a_0 units)")')

  write (6, '(7x,i3,8x,a6," tau(",i3,") = (",3f11.7,"  )")') &
             (na, atm(ityp(na)), na, (tau(ipol,na), ipol=1,3), na=1,nat)
  !
  !  output of starting magnetization
  !
  if (iverbosity.eq.1) then
     !
     !   allocate work space
     !
     allocate (xau(3,nat))
     !
     !     Compute the coordinates of each atom in the basis of the direct la
     !     vectors
     !
     do na = 1, nat
        do ipol = 1, 3
           xau(ipol,na) = bg(1,ipol)*tau(1,na) + bg(2,ipol)*tau(2,na) + &
                          bg(3,ipol)*tau(3,na)
        enddo
     enddo
     !
     !   description of the atoms inside the unit cell
     !   (in crystallographic coordinates)
     !
     write (6, '(/,3x,"Crystallographic axes")')
     write (6, '(/,5x,"site n.     atom        ", &
          &             "          positions (cryst. coord.)")')

     write (6, '(7x,i2,8x,a6," tau(",i3,") = (",3f11.7,"  )")') &
           (na, atm(ityp(na)), na,  (xau(ipol,na), ipol=1,3), na=1,nat)
     !
     !   deallocate work space
     !
     deallocate(xau)
  endif

  if (lgauss) then
     write (6, '(/5x,"number of k points=",i5, &
          &               "  gaussian broad. (ryd)=",f8.4,5x, &
          &               "ngauss = ",i3)') nkstot, degauss, ngauss
  else if (ltetra) then
     write(6,'(/5x,"number of k points=",i5, &
          &        " (tetrahedron method)")') nkstot
  else
     write (6, '(/5x,"number of k points=",i5)') nkstot

  endif
  write (6, '(23x,"cart. coord. in units 2pi/a_0")')
  do ik = 1, nkstot
     write (6, '(8x,"k(",i4,") = (",3f12.7,"), wk =",f12.7)') ik, &
          (xk (ipol, ik) , ipol = 1, 3) , wk (ik)
  enddo
  if (iverbosity.eq.1) then
     write (6, '(/23x,"cryst. coord.")')
     do ik = 1, nkstot
        do ipol = 1, 3
           xkg(ipol) = at(1,ipol)*xk(1,ik) + at(2,ipol)*xk(2,ik) + &
                       at(3,ipol)*xk(3,ik)
           ! xkg are the component in the crystal RL basis
        enddo
        write (6, '(8x,"k(",i4,") = (",3f12.7,"), wk =",f12.7)') &
             ik, (xkg (ipol) , ipol = 1, 3) , wk (ik)
     enddo
  endif
  ngmtot = ngm
#ifdef __PARA
  call ireduce (1, ngmtot)
#endif
  write (6, '(/5x,"G cutoff =",f10.4,"  (", &
       &       i7," G-vectors)","     FFT grid: (",i3, &
       &       ",",i3,",",i3,")")') gcutm, ngmtot, nr1, nr2, nr3
  if (doublegrid) then
     ngmtot = ngms
#ifdef __PARA
     call ireduce (1, ngmtot)
#endif
     write (6, '(5x,"G cutoff =",f10.4,"  (", &
          &    i7," G-vectors)","  smooth grid: (",i3, &
          &    ",",i3,",",i3,")")') gcutms, ngmtot, nr1s, nr2s, nr3s
  endif

  if (isolve.eq.2) then
     write (6, * )
     write (6, '(5x,"initial CG steps:   ",1i5)') diis_start_cg
     write (6, '(5x,"reduced basis size: ",1i5)') diis_ndim
  endif

#ifdef FLUSH
  call flush (6)
#endif
  return
end subroutine summary

