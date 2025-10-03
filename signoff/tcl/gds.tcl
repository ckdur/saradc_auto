# gds write from def and lef
set scalefac [tech lambda]
if {[lindex $scalefac 1] < 2} {
    scalegrid 1 2
}

crashbackups stop
drc euclidean on
snap lambda

# Read the cells. Do not save mags
gds read $env(ROOT_DIR)/lib/$env(TECH).gds

# Read the tech lef file
lef read $env(ROOT_DIR)/lib/$env(TECH).tlef

# Read the def file
def read $env(DEF)

# Load the top cell
# read $env(TOP)
select top cell

# Convert to gds
gds write $env(GDS)

exit

