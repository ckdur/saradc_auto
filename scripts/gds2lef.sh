#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GDS=$1 CSV=$2 magic -dnull -noconsole -rcfile $3 $SCRIPT_DIR/gds2lef.magic.tcl

