ROOT_DIR=$(abspath ../)
include $(ROOT_DIR)/settings.mk
PNR_DIR=$(abspath ../pnr)
SYN_DIR=$(abspath ../syn)
SIGN_DIR=$(abspath .)

GDS=$(SIGN_DIR)/outputs/$(TOP).gds
DEF=$(PNR_DIR)/outputs/$(TOP).def

GDSPRE=$(SIGN_DIR)/outputs/$(TOP).pre.gds
DEFPRE=$(PNR_DIR)/outputs/$(TOP).pre.def

SPICE=$(SIGN_DIR)/outputs/$(TOP).spice
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

gdspre: $(GDSPRE)

gds: $(GDS)

$(SIGN_DIR)/outputs/%.gds: $(PNR_DIR)/outputs/%.def
	mkdir -p $(SIGN_DIR)/outputs
	mkdir -p $(SIGN_DIR)/reports
ifeq ($(PDK_FILE),none)
	klayout -zz -rd design_name=$(TOP) \
	        -rd in_def=$< \
	        -rd lef_files="$(ROOT_DIR)/cells/$(TECH).tech.lef $(ROOT_DIR)/cells/$(TECH).lef $(ROOT_DIR)/cells/SARADC_CELL_INVX0_ASSW.lef $(ROOT_DIR)/cells/SARADC_CELL_INVX16_ASCAP.lef $(ROOT_DIR)/cells/SARADC_FILLTIE2.lef $(ROOT_DIR)/cells/SARADC_FILL1.lef $(ROOT_DIR)/cells/SARADC_FILL1_NOPOWER.lef" \
	        -rd in_files="$(ROOT_DIR)/cells/$(TECH).gds $(ROOT_DIR)/cells/SARADC_CELL_INVX0_ASSW.gds $(ROOT_DIR)/cells/SARADC_CELL_INVX16_ASCAP.gds $(ROOT_DIR)/cells/SARADC_FILLTIE2.gds $(ROOT_DIR)/cells/SARADC_FILL1.gds $(ROOT_DIR)/cells/SARADC_FILL1_NOPOWER.gds" \
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
	python3 $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/run_drc.py --path=$(GDS) --mp=10 --run_dir=$(SIGN_DIR)/reports/ --topcell=$(TOP) --run_mode=flat --no_density --density_thr=10 --antenna
#	python3 $(SIGN_DIR)/tcl/klayout_gds_drc_check.py --gds_input_file_path $(GDS) --output_directory $(SIGN_DIR)/reports --design_name $(TOP) --drc_rules $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/sg13g2_minimal.lydrc

drc_magic: $(GDS)
	magic -dnull -noconsole -rcfile $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc $(SIGN_DIR)/tcl/run_magic_drc.tcl

ADC_CELLS ?= SARADC_CELL_INVX0_ASSW SARADC_CELL_INVX16_ASCAP SARADC_FILLTIE2 SARADC_FILL1 SARADC_FILL1_NOPOWER
ADC_CDLS = $(ADC_CELLS:%=$(ROOT_DIR)/cells/%.cdl)

$(SPICE): $(ROOT_DIR)/cells/$(TECH).cdl $(ADC_CDLS) $(NET)
	cat $(ROOT_DIR)/cells/$(TECH).cdl $(ADC_CDLS) $(NET) > $(SPICE)

lvs: $(GDS) $(SPICE)
	python3 $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/lvs/run_lvs.py --layout=$(GDS) --netlist=$(SPICE) --run_dir=$(SIGN_DIR)/reports/ --topcell=$(TOP) --run_mode=flat --verbose
#	klayout -b -r $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/lvs/sg13g2.lvs -rd in_gds=$(GDS) -rd report_file=$(SIGN_DIR)/reports/lvs_report.lvsdb -rd cdl_file=$(SPICE) -rd target_netlist=$(SIGN_DIR)/reports/$(TOP).lay.cdl

clean:
	rm -vrf  outputs reports

.PHONY: all manual clean

