ROOT_DIR=$(abspath ../)
include $(ROOT_DIR)/settings.mk
SYN_DIR=$(abspath ../syn)
SIGN_DIR=$(abspath .)
# PnR to sign off, and where to write. The legacy (flat) PnR:
#   make -C signoff PNR_DIR=../pnr_legacy OUT_DIR=outputs_legacy REP_DIR=reports_legacy
# A macro of the hierarchical PnR: make -C signoff TOP=SARADC_CDAC
PNR_DIR?=../pnr
OUT_DIR?=outputs
REP_DIR?=reports
override PNR_DIR:=$(abspath $(PNR_DIR))
override OUT_DIR:=$(abspath $(OUT_DIR))
override REP_DIR:=$(abspath $(REP_DIR))
# Macros the top instantiates (LEF, GDS and CDL from their own PnR/signoff)
MACROS?=$(if $(filter SARADC,$(TOP)),$(if $(findstring pnr_legacy,$(PNR_DIR)),,SARADC_CDAC),)
MACRO_LEFS=$(MACROS:%=$(PNR_DIR)/outputs/%.lef)
MACRO_GDSS=$(MACROS:%=$(OUT_DIR)/%.gds)
MACRO_CDLS=$(MACROS:%=$(PNR_DIR)/outputs/%.cdl)

GDS=$(OUT_DIR)/$(TOP).gds
DEF=$(PNR_DIR)/outputs/$(TOP).def

GDSPRE=$(OUT_DIR)/$(TOP).pre.gds
DEFPRE=$(PNR_DIR)/outputs/$(TOP).pre.def

SPICE=$(OUT_DIR)/$(TOP).spice
NET=$(PNR_DIR)/outputs/$(TOP).cdl

PDK_ROOT?=/opt/ext/OpenPDKs/IHP-Open-PDK
PDK?=ihp-sg13g2
TECH_PDK=$(PDK_ROOT)/$(PDK)
#PDK_FILE ?= $(TECH_PDK)/libs.tech/magic/$(PDK).magicrc
PDK_FILE?=none
PDK_KFILE ?= $(TECH_PDK)/libs.tech/klayout/tech/sg13g2.lyp
PDK_KNFILE ?= $(TECH_PDK)/libs.tech/klayout/tech/sg13g2.lyt
export PDK_ROOT
export PDK

all: gds drc lvs

gdspre: $(GDSPRE)

gds: $(GDS)

$(OUT_DIR)/%.gds: $(PNR_DIR)/outputs/%.def
	mkdir -p $(OUT_DIR)
	mkdir -p $(REP_DIR)
ifeq ($(PDK_FILE),none)
	klayout -zz -rd design_name=$(TOP) \
	        -rd in_def=$< \
	        -rd lef_files="$(ROOT_DIR)/cells/$(TECH).tech.lef $(ROOT_DIR)/cells/$(TECH).lef $(ROOT_DIR)/cells/SARADC_CELL_INVX0_ASSW.lef $(ROOT_DIR)/cells/SARADC_CELL_INVX16_ASCAP.lef $(ROOT_DIR)/cells/SARADC_FILLTIE2.lef $(ROOT_DIR)/cells/SARADC_FILL1.lef $(ROOT_DIR)/cells/SARADC_FILL1_NOPOWER.lef $(MACRO_LEFS)" \
	        -rd in_files="$(ROOT_DIR)/cells/$(TECH).gds $(ROOT_DIR)/cells/SARADC_CELL_INVX0_ASSW.gds $(ROOT_DIR)/cells/SARADC_CELL_INVX16_ASCAP.gds $(ROOT_DIR)/cells/SARADC_FILLTIE2.gds $(ROOT_DIR)/cells/SARADC_FILL1.gds $(ROOT_DIR)/cells/SARADC_FILL1_NOPOWER.gds $(MACRO_GDSS)" \
	        -rd seal_file="" \
	        -rd out_file=$@ \
	        -rd tech_file=$(TECH_PDK)/libs.tech/klayout/tech/sg13g2.lyt \
	        -rd layer_map=$(TECH_PDK)/libs.tech/klayout/tech/sg13g2.map \
	        -r $(SIGN_DIR)/tcl/def2stream.py
else
	magic -dnull -noconsole -rcfile $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc $(SIGN_DIR)/tcl/gds.tcl
endif

view: $(GDS)
	klayout -nn $(PDK_KNFILE) -s $(GDS)

viewpre: $(GDSPRE)
	klayout -nn $(PDK_KNFILE) -s $(GDSPRE)

drc: $(GDS)
	python3 $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/run_drc.py --path=$(GDS) --mp=10 --run_dir=$(REP_DIR)/ --topcell=$(TOP) --run_mode=flat --no_density --density_thr=10 --antenna
#	python3 $(SIGN_DIR)/tcl/klayout_gds_drc_check.py --gds_input_file_path $(GDS) --output_directory $(SIGN_DIR)/reports --design_name $(TOP) --drc_rules $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/sg13g2_minimal.lydrc

drc_magic: $(GDS)
	magic -dnull -noconsole -rcfile $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc $(SIGN_DIR)/tcl/run_magic_drc.tcl

ADC_CELLS ?= SARADC_CELL_INVX0_ASSW SARADC_CELL_INVX16_ASCAP SARADC_FILLTIE2 SARADC_FILL1 SARADC_FILL1_NOPOWER
ADC_CDLS = $(ADC_CELLS:%=$(ROOT_DIR)/cells/%.cdl)

$(SPICE): $(ROOT_DIR)/cells/$(TECH).cdl $(ADC_CDLS) $(MACRO_CDLS) $(NET)
	mkdir -p $(OUT_DIR)
	cat $(ROOT_DIR)/cells/$(TECH).cdl $(ADC_CDLS) $(MACRO_CDLS) $(NET) > $(SPICE)

SPICE_FLATSTD=$(OUT_DIR)/$(TOP).flatstd.spice

$(SPICE_FLATSTD): $(SPICE) $(SIGN_DIR)/tcl/flatstd.py
	klayout -b -r $(SIGN_DIR)/tcl/flatstd.py -rd src=$(SPICE) -rd dst=$@

# Flat LVS, run directly with the KLayout runset. The standard cells are
# flattened in the schematic, and the top port check is relaxed because the
# pin labels of the flattened standard cells appear as extra top-level ports.
lvs: $(GDS) $(SPICE_FLATSTD)
	mkdir -p $(REP_DIR)
	cd $(REP_DIR) && klayout -b -r $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/lvs/sg13g2.lvs \
	        -rd input=$(GDS) -rd schematic=$(SPICE_FLATSTD) -rd topcell=$(TOP) \
	        -rd run_mode=flat -rd top_lvl_pins=true -rd ignore_top_ports_mismatch=true \
	        -rd report=$(REP_DIR)/$(TOP).lvsdb \
	        -rd target_netlist=$(REP_DIR)/$(TOP)_extracted.cir \
	        -rd log=$(REP_DIR)/$(TOP).lvs.log
	grep -q "Netlists match" $(REP_DIR)/$(TOP).lvs.log

clean:
	rm -vrf $(OUT_DIR) $(REP_DIR)

.PHONY: all manual clean

