#!/bin/bash
# Build a serial (OpenMP, no MPI) NuHamil.exe linked against OpenBLAS on point7.
#
# Usage, on the point7 login node:  bash jobs/build_point7.sh [output]
#   output: where to put the binary (default: <checkout>/exe/NuHamil_point7.exe, ignored by git)
# Installing it into the calculation directory is a separate, explicit step (jobs/README.md).
#
# The checkout is copied to a temporary directory first, so its obj/, mod/ and exe/ (the MPI
# build) are left alone. The plain Makefile links -lblas -llapack, which on point7 is Netlib
# reference BLAS (single-threaded, unoptimized); LFLAGS below replaces it by OpenBLAS (BLAS and
# LAPACK), found at run time through the rpath.
set -euo pipefail

SRC=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-$SRC/exe/NuHamil_point7.exe}
LF="-I/usr/local/include -L/usr/local/lib -lgsl -lgslcblas -lz -lhdf5_fortran -lm -ldl"
LF="$LF -L/opt/library/openblas/lib -lopenblas -Wl,-rpath,/opt/library/openblas/lib"

B=$(mktemp -d /tmp/nuhamil_build_XXXXXX)
trap 'rm -rf "$B"' EXIT
rsync -a --exclude obj --exclude mod --exclude 'exe/*.exe' --exclude result --exclude bin \
    --exclude input_nn_files --exclude '*.me2j.gz' --exclude '*.minipack' "$SRC/" "$B/"
echo "source: $(git -C "$SRC" log -1 --format='%h %s')"
git -C "$SRC" status --short | sed 's/^/  uncommitted: /'

cd "$B"
if ! bash -lc "module load gsl/2.7.1 hdf5/1.14.1 openblas/0.3.10 && make -j 8 MPI=off LFLAGS=\"$LF\"" \
        > build.log 2>&1; then
    tail -20 build.log
    exit 1
fi
cp exe/NuHamil.exe "$OUT"

echo "built:   $OUT"
echo "version: $(strings "$OUT" | grep -o 'main:[0-9a-f]*' | head -1)"
readelf -d "$OUT" | grep -E 'NEEDED.*(blas|lapack)|RUNPATH' | sed 's/^ */  /'
if readelf -d "$OUT" | grep -q -E 'NEEDED.*lib(blas|lapack)\.so'; then
    echo "ERROR: linked to generic libblas/liblapack, not OpenBLAS" >&2
    exit 1
fi
sha256sum "$OUT"
