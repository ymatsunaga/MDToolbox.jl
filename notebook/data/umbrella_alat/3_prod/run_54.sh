#!/bin/bash

NPROC=2
mpirun -np $NPROC sander.MPI -O \
 -p prmtop \
 -i run_54.in \
 -c ../2_eq/run_54.rst \
 -o run_54.out \
 -r run_54.rst \
 -x run_54.nc

