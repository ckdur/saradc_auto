# Cell libraries per technology (cells/README.md).
#
#   make -C cells TECH=sky130f          # build cells/sky130f from stdcell-gen
#   make -C cells TECH=sky130f check    # DRC/LVS of the ADC cells
#
# cells/sg13g2f holds the cells of the taped-out chip and is not rebuilt here (its own Makefile
# has the old targets).
PRJ_DIR=$(abspath ..)
ROOT_DIR=$(PRJ_DIR)
include $(PRJ_DIR)/settings.mk
TOOLS=$(PRJ_DIR)/cells/tools

# stdcell-gen, with the float library of TECH generated (make -f Makefile.$(TECH) layouts there)
STDCELL_GEN ?= $(HOME)/Documents/IIZUKA_LAB/stdcell-gen
STDCELL_TMP = $(STDCELL_GEN)/tmp
TECH_JSON = $(PRJ_DIR)/cells/tech/$(TECH).json
ICS55_PDK_DIR ?= $(HOME)/Documents/SymbioticEDA/ics55/icsprout55-pdk
DOCKER_IMAGE ?= factory.symbioticeda.com/asic-all:dev
export ICS55_PDK_DIR

# The standard cells: the ones the ADC uses (synthesis, RTL, PnR), plus INVD0 and INVD12 for the
# switch and the unit capacitor
STD_CELLS ?= INVD0 INVD1 INVD6 INVD8 INVD12 \
BUFFD0 BUFFD1 BUFFD2 BUFFD4 BUFFD8 BUFFD16 DEL4 \
ND2D1 ND2D2 ND3D1 NR2D1 NR3D4 \
AN2D1 AN2D4 OR2D1 AO21D1 OA21D1 AOI21D1 OAI21D1 OAI211D4 \
XOR2D1 XNR2D1 MUX2D1 DFQD1 DFCNQD1 TIEH TIEL \
FILL1 FILL2 FILL4 FILL8 TAPCELL ANTENNA
# The ones the RTL instantiates directly (blackboxes of the analog synthesis)
BLACKBOX_CELLS ?= TIEH TIEL INVD1 INVD6 INVD8 OAI211D4 ND2D2 AN2D4 NR3D4 BUFFD0 BUFFD2 BUFFD4 BUFFD8 BUFFD16 DEL4
ADC_CELLS = SARADC_CELL_INVX0_ASSW SARADC_CELL_INVX16_ASCAP SARADC_FILLTIE2 SARADC_FILL1 SARADC_FILL1_NOPOWER

ifeq ($(TECH),sg13g2f)
all build check:
	@echo "cells/sg13g2f are the taped-out cells and are not rebuilt (see cells/sg13g2f/Makefile)"
else
all: build

build: $(CELLS_DIR)/$(TECH).gds $(CELLS_DIR)/$(TECH).tech.lef $(CELLS_DIR)/$(TECH).lib

# The liberty and verilog models, from the per-cell liberty files of stdcell-gen
# (make -f Makefile.$(TECH) char_lib PYTHON3=<venv>/bin/python there)
$(CELLS_DIR)/$(TECH).lib: $(CELLS_DIR)/$(TECH).gds $(TOOLS)/merge_lib.py $(wildcard $(STD_CELLS:%=$(STDCELL_TMP)/$(TECH)_%.lib))
	mkdir -p $(CELLS_DIR)
	python3 $(TOOLS)/merge_lib.py $(TECH) $(STDCELL_TMP) $(CELLS_DIR) $(CELLS_DIR)/$(TECH).lef $(STD_CELLS)

$(CELLS_DIR)/$(TECH).gds: $(TECH_JSON) $(TOOLS)/build_cells.py $(STD_CELLS:%=$(STDCELL_TMP)/$(TECH)_%.gds)
	klayout -b -r $(TOOLS)/build_cells.py -rd tech=$(TECH_JSON) -rd src=$(STDCELL_TMP) -rd out=$(CELLS_DIR) \
	  -rd cells="$(STD_CELLS)" -rd blackbox="$(BLACKBOX_CELLS)"

# The tech LEF of the PDK (gf180mcuD only exists in the docker image)
$(CELLS_DIR)/$(TECH).tech.lef: $(TECH_JSON)
	mkdir -p $(CELLS_DIR)
	src=$$(python3 -c "import json,os;print(os.path.expandvars(json.load(open('$(TECH_JSON)'))['techlef']))"); \
	if [ -f "$$src" ]; then cp "$$src" $@; \
	else docker run --rm $(DOCKER_IMAGE) bash -lc "cat $$(python3 -c "import json;print(json.load(open('$(TECH_JSON)'))['techlef'])")" > $@; fi
	grep -q "^LAYER" $@

check: build
	bash $(TOOLS)/check_cells.sh $(TECH) $(CELLS_DIR) $(CELLS_DIR)/reports $(ADC_CELLS)
endif

clean:
	rm -rf $(CELLS_DIR)/reports

.PHONY: all build check clean
