#!/bin/sh
# If we want to install it globally, you don't want to run this file

BASEDIR=$(realpath $(dirname "$0"))

rm -r ${BASEDIR}/build
meson ${BASEDIR}/build
meson install -C ${BASEDIR}/build
sed -i "s|libgalore.so|${BASEDIR}/build/src/libgalore.so|" ${BASEDIR}/build/src/Galore-0.1.gir
g-ir-compiler ${BASEDIR}/build/src/Galore-0.1.gir --output ${BASEDIR}/build/src/Galore-0.1.typelib
