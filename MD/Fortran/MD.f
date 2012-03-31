C
C  Simple molecular dynamics code.
C  $Id: MD.f,v 1.2 2002/01/31 16:43:14 spb Exp spb $
C
C This program implements:
C     long range inverse square forces between particles. F = G * m1*m2 / r**2
C     viscosity term     F = -u V
C If 2 particles approach closer than Size we flip the direction of the
C interaction force to approximate a collision.
C
C
C This program was developed as part of a code optimisation course
C and is therefore deliberately inefficient.
C
      SUBROUTINE evolve( count, dt)
      IMPLICIT NONE
      INCLUDE 'coord.inc'
      INTEGER count, step
      DOUBLE PRECISION dt
      DOUBLE PRECISION force
      INTEGER i,j,k,l

C
C Loop over timesteps.
C
      DO step = 1,count
        write(*,*) 'timestep ',step
        write(*,*) 'collisions ',collisions

C set the viscosity term in the force calculation
        DO j=1,Ndim
          CALL visc_force(Nbody,f(1,j),visc,vel(1,j))
        END DO

C calculate distance from central mass
        DO k=1,Nbody
          r(k) = 0.0
        END DO
        DO i=1,Ndim
          call add_norm(Nbody,r,pos(1,i))
        END DO
        DO k=1,Nbody
          r(k) = SQRT(r(k))
        END DO

C calculate central force

        DO i=1,Nbody
          DO l=1,Ndim
                f(i,l) = f(i,l) - 
     $              force(G*mass(i)*M_central,pos(i,l),r(i))
          END DO
        END DO

C calculate pairwise separation of particles
        k = 1
        DO i=1,Nbody
          DO j=i+1,Nbody
            DO l=1,Ndim
              delta_x(k,l) = pos(i,l) - pos(j,l)
            END DO
            k = k + 1
          END DO
        END DO

C calculate norm of seperation vector
        DO k=1,Npair
          delta_r(k) = 0.0
        END DO
        DO i=1,Ndim
          call add_norm(Npair,delta_r,delta_x(1,i))
        END DO
        DO k=1,Npair
          delta_r(k) = SQRT(delta_r(k))
        END DO

C
C add pairwise forces.
C
        k = 1
        DO i=1,Nbody
          DO j=i+1,Nbody
            DO l=1,Ndim
C  flip force if close in
              IF( delta_r(k) .GE. Size ) THEN
                f(i,l) = f(i,l) - 
     $              force(G*mass(i)*mass(j),delta_x(k,l),delta_r(k))
                f(j,l) = f(j,l) +
     $              force(G*mass(i)*mass(j),delta_x(k,l),delta_r(k))
              ELSE
                f(i,l) = f(i,l) +
     $               force(G*mass(i)*mass(j),delta_x(k,l),delta_r(k))
                f(j,l) = f(j,l) -
     $               force(G*mass(i)*mass(j),delta_x(k,l),delta_r(k))
                collisions = collisions + 1
              END IF
            END DO
            k = k + 1
          END DO
        END DO

C update positions
        DO i=1,Nbody
          DO j=1,Ndim
            pos(i,j) = pos(i,j) + dt * vel(i,j)
          END DO
        END DO

C update velocities
        DO i=1,Nbody
          DO j=1,Ndim
            vel(i,j) = vel(i,j) + dt * (f(i,j)/mass(i))
          END DO
        END DO


      END DO

      END

