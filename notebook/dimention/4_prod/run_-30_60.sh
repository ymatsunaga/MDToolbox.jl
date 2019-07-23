#!/bin/bash

NPROC=8
mpirun -np $NPROC sander.MPI -O \
 -p prmtop \
 -i run_-30_60.in \
 -c ../3_eq/run_-30_60.rst \
 -o run_-30_60.out \
 -r run_-30_60.rst \
 -x run_-30_60.nc
