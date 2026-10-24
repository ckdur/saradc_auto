#!/bin/bash
# Xyce (MPI, plugin support) against Trilinos 14 in /opt/ext/OpenLane, rebuilt for OpenMPI 5.
# Same options as ../build.
cmake \
  -DCMAKE_C_COMPILER=/usr/bin/mpicc \
  -DCMAKE_CXX_COMPILER=/usr/bin/mpic++ \
  -DCMAKE_C_FLAGS="-O3 -fPIC" \
  -DCMAKE_CXX_FLAGS="-O3 -fPIC -include cstdint" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/opt/ext/OpenLane \
  -DTrilinos_ROOT=/opt/ext/OpenLane \
  -DBUILD_SHARED_LIBS=ON \
  -DXyce_PLUGIN_SUPPORT=ON \
  ..
