#!/usr/bin/env bash
# Rebuild the compiled device models of the PDK from its Verilog-A sources (PSP103, r3_cmc):
# OSDI for ngspice (OpenVAF) and plugins for Xyce (ADMS + buildxyceplugin). The PDK checkout
# does not ship current binaries; both outputs are git-ignored in IHP-Open-PDK.
#
# Usage: source ~/init_openlane.sh; sim/tools/build_models.sh
# The previous binaries are kept in old-<date>/ next to the new ones.
set -e
V=$PDK_ROOT/$PDK/libs.tech/verilog-a
STAMP=old-$(date +%Y%m%d)

# ngspice: libs.tech/ngspice/osdi/*.osdi
O=$PDK_ROOT/$PDK/libs.tech/ngspice/osdi
mkdir -p "$O/$STAMP" && cp -p "$O"/*.osdi "$O/$STAMP/" 2>/dev/null || true
(cd "$V" && bash openvaf-compile-va.sh)

# Xyce: libs.tech/xyce/plugins/*.so, built out of tree
B=$(mktemp -d)
for m in psp103 r3_cmc; do
    cp -r "$V/$m" "$B/"
    (cd "$B/$m" && rm -rf CMake* Makefile *.so cmake_install.cmake && buildxyceplugin $m.va . > build.out 2>&1)
done
P=$PDK_ROOT/$PDK/libs.tech/xyce/plugins
mkdir -p "$P/$STAMP" && cp -p "$P"/*.so "$P/$STAMP/" 2>/dev/null || true
cp "$B/psp103/libXyce_Plugin_PSP103_VA.so" "$B/r3_cmc/libXyce_Plugin_r3_cmc.so" "$P/"
rm -rf "$B"
ls -la "$O" "$P"
