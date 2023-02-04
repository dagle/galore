#!/bin/bash
# If we want to install it globally, you don't want to run this file

NAME=$(dirname "$0")
BASEDIR=$(realpath "${NAME}")

if [ -d "${BASEDIR}/build" ]; then
	rm -r "${BASEDIR}"/build
fi
meson setup "${BASEDIR}"/build
meson compile -C "${BASEDIR}"/build
sed -i "s|libgalore.so|${BASEDIR}/build/src/libgalore.so|" "${BASEDIR}"/build/src/Galore-0.1.gir
g-ir-compiler "${BASEDIR}"/build/src/Galore-0.1.gir --output "${BASEDIR}"/build/src/Galore-0.1.typelib
