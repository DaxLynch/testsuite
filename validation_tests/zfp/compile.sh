#!/bin/bash -e
. ./setup.sh
set -x
#spack load openblas threads=openmp
#spack load hypre+internal-superlu
#spack load mpich
export CXX=$TEST_CXX
export CC=$TEST_CC
make diffusion
make inplace 
#make iterator
make simple 
