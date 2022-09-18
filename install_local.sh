#!/bin/sh
# If we want to install it globally, you don't want to run this file
meson build
meson install -C build
sed -i "s|libgalore.so|$(pwd)/build/src/libgalore.so|" /home/dagle/code/galore/build/src/Galore-0.1.gir
g-ir-compiler build/src/Galore-0.1.gir --output build/src/Galore-0.1.typelib
