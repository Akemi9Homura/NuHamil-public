#!/bin/bash
# NuHamil runtime environment on point7 (/tns/mengziyan). Installed as
# /tns/mengziyan/job-nuhamil/sourceme.sh; job scripts source it before running NuHamil.exe.
# Do not 'module purge': the default environment is what provides gsl and hdf5.

# gsl and hdf5 from /opt/library. The current NuHamil.exe links OpenBLAS through its rpath
# (see BINARY_INFO in the calculation directory). lapack-3.11.0 is Netlib reference BLAS/LAPACK:
# it is here only for the older binaries kept there (NuHamil.exe.c366c85, .1decf23-refblas),
# which ask for the generic libblas.so.3 / liblapack.so.3 and would pick it up from this path.
export LD_LIBRARY_PATH=/opt/library/lapack-3.11.0/lib:/opt/library/gsl-2.7.1/lib:/opt/library/hdf5-1.14.1/lib:/tns/mengziyan/usr/lib:${LD_LIBRARY_PATH:-}

# HDF5 needs file locking off to read Kai Hebeler's .h5 files on the network file system
export HDF5_USE_FILE_LOCKING=FALSE

# OpenMP
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export OMP_PLACES=cores
export OMP_PROC_BIND=spread
export OMP_STACKSIZE=512M

# BLAS threads. 1 = BLAS runs in the calling thread, which is safe everywhere, including inside
# OpenMP loops (3N code). OpenBLAS on point7 is a pthreads build, not an OpenMP one: raise
# OPENBLAS_NUM_THREADS (after sourcing this file) only for code paths whose BLAS calls are outside
# OpenMP regions, e.g. the lab-frame transformation of two-body operators (jobs/README.md).
export OPENBLAS_NUM_THREADS=1
export GOTO_NUM_THREADS=1
export MKL_NUM_THREADS=1

ulimit -s unlimited
