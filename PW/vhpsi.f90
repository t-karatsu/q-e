!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------

subroutine vhpsi (ldap, np, mp, psip, hpsi)
  !-----------------------------------------------------------------------
  !
  ! This routine computes the Hubbard potential applied to the electronic
  ! of the current k-point, the result is added to hpsi
  !
#include "machine.h"

  use pwcom
  implicit none
  integer :: ldap, np, mp
  complex(kind=DP) :: psip (ldap, mp), hpsi (ldap, mp)
  !
  integer :: ibnd, i, na, nt, n, counter, m1, m2, l
  integer, allocatable ::  offset (:)
  ! offset of d electrons of atom na in the natomwfc ordering
  complex(kind=DP) :: ZDOTC, temp
  complex(kind=DP), allocatable ::  proj (:,:)
  !
  allocate ( offset(nat), proj(natomwfc,mp) ) 
  counter = 0  
  do na = 1, nat  
     nt = ityp (na)  
     do n = 1, nchi (nt)  
        if (oc (n, nt) .gt.0.d0.or..not.newpseudo (nt) ) then  
           l = lchi (n, nt)  
           if (l.eq.Hubbard_l(nt)) offset (na) = counter  
           counter = counter + 2 * l + 1  
        endif
     enddo
  enddo
  !
  if (counter.ne.natomwfc) call error ('vhpsi', 'nstart<>counter', 1)
  do ibnd = 1, mp
     do i = 1, natomwfc
        proj (i, ibnd) = ZDOTC (np, swfcatom (1, i), 1, psip (1, ibnd), 1)
     enddo
  enddo
#ifdef PARA
  call reduce (2 * natomwfc * mp, proj)
#endif
  do ibnd = 1, mp  
     do na = 1, nat  
        nt = ityp (na)  
        if (Hubbard_U(nt).ne.0.d0 .or. Hubbard_alpha(nt).ne.0.d0) then  
           do m1 = 1, 2 * Hubbard_l(nt) + 1 
              temp = proj (offset(na)+m1, ibnd)  
              do m2 = 1, 2 * Hubbard_l(nt) + 1 
                 temp = temp - 2.d0 * ns (na, current_spin, m1, m2) * &
                                      proj (offset(na)+m2, ibnd)
              enddo

              temp = temp * Hubbard_U(nt)/2.d0
              temp = temp + &
                     proj(offset(na)+m1,ibnd) * Hubbard_alpha(nt)

              call ZAXPY (np, temp, swfcatom(1,offset(na)+m1), 1, &
                                    hpsi(1,ibnd),              1)
           enddo
        endif
     enddo

  enddo
  deallocate (offset, proj)
  return

end subroutine vhpsi

