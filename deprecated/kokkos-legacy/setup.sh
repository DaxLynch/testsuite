#!/bin/bash
. ../../setup.sh
#spack load libpciaccess
#spack load libiconv
#spack load numactl
#spack load hwloc
spackLoadUniqueNoR tau #@develop
#spackLoadUnique kokkos
#kokkosHash=$(spackLoadUnique kokkos) #+openmp
spackLoadUniqueNoR kokkos-legacy
#spack load -r kokkos
#module list
export KOKKOS=$KOKKOS_LEGACY_ROOT #`spack location -i ${kokkosHash}`
