#!/bin/bash -e
. ./setup.sh
set -x
export OMP_PROC_BIND=spread 
export OMP_PLACES=threads
export OMP_NUM_THREADS=8
./build_cmake_installed/build/example 500000000
#./build/example_with_kokkos 500000000
#./build/example_cmake 500000000
