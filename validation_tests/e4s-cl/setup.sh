#!/bin/bash
. ../../setup.sh
THISDIR=`basename "$PWD"`
spackLoadUnique $THISDIR
spackLoadUnique mpich
#export E4S_TEST_SOURCE=>>>SOURCEFILE.EXT<<<
#export E4S_TEST_FLAGS=>>>FLAGS<<<
#export E4S_TEST_LIBS=>>>LIBS<<<
