# gds write from def and lef
set scalefac [tech lambda]
if {[lindex $scalefac 1] < 2} {
    scalegrid 1 2
}

crashbackups stop
drc euclidean on
snap lambda

# Read the cells. Do not save mags
# gds read $env(ROOT_DIR)/lib/$env(TECH).gds

# Read the tech lef file
lef read $env(ROOT_DIR)/lib/$env(TECH).tlef
lef read $env(ROOT_DIR)/lib/$env(TECH).lef

# Read the def file
def read $env(DEF)

set extdir $env(SIGN_DIR)/outputs/magic_spice_ext
file mkdir $extdir
cd $extdir

extract do local
extract no capacitance
extract no coupling
extract no resistance
extract no adjust
# extract unique

extract
ext2spice lvs

ext2spice -o $env(SPICE)
feedback save $env(SIGN_DIR)/outputs/$env(TOP).feedback.txt

exit

