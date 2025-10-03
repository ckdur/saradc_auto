ROOT_DIR=$(abspath ../../)
PRJ_DIR=$(abspath ../)
include $(PRJ_DIR)/settings.mk
CELLS_DIR=$(abspath .)
SCRIPTS_DIR=$(PRJ_DIR)/scripts

gds2lef_file=$(SCRIPTS_DIR)/gds2lef.sh

# Force the magic PDK file
PDK_FILE=$(TECH_PDK)/libs.tech/magic/ihp-sg13g2.magicrc
PDK_KFILE ?= $(TECH_PDK)/libs.tech/klayout/tech/sg13g2.lyp
PDK_KNFILE ?= $(TECH_PDK)/libs.tech/klayout/tech/sg13g2.lyt

CELLS ?= SARADC_CELL_INVX0_ASSW SARADC_CELL_INVX16_ASCAP SARADC_FILLTIE2 SARADC_FILL1 SARADC_FILL1_NOPOWER ANTENNA

LEFS = $(CELLS:%=%.lef)

all: $(LEFS)

%.lef: %.gds
	bash $(gds2lef_file) $*.gds $*.port.csv $(PDK_FILE)
	mv $*.$*.lef $*.lef

GDS=$(CELLS_DIR)/sg13g2f.gds
SPICE=$(CELLS_DIR)/sg13g2f.cdl
LVS_CELLS=INVD0 INVD1 INVD2 INVD4 INVD6 INVD8 INVD12 INVD16 \
BUFFD0 BUFFD1 BUFFD2 BUFFD4 BUFFD6 BUFFD8 BUFFD12 BUFFD16 \
DEL0 DEL005 DEL015 DEL02 DEL2 DEL4 \
ND2D0 ND2D1 ND2D2 ND2D4 \
NR2D0 NR2D1 NR2D2 NR2D4 \
ND3D0 ND3D1 ND3D2 \
NR3D0 NR3D1 NR3D2 NR3D4 \
OAI211D0 OAI211D1 OAI211D4 \
XOR2D0 XOR2D1 XOR2D2 \
XNR2D0 XNR2D1 XNR2D2 \
AN2D0 AN2D1 AN2D2 AN2D4 \
OR2D0 OR2D1 OR2D2 OR2D4 \
OA21D1 OA21D2 \
AO21D0 AO21D1 AO21D2 \
OAI21D0 OAI21D1 \
AOI21D0 AOI21D1 \
MUX2D0 MUX2D1 MUX2D2 MUX2D4 \
DFQD1 DFCNQD1 \
TIEH TIEL
LVS_REPORTS=$(LVS_CELLS:%=reports/%.lvsdb)

LVS_CELLS_REJECTED=AO21D4 AOI21D2 AOI21D4 DEL01 ND3D4 OA21D0 OA21D4 OAI21D2 OAI21D4 OAI211D2 XNR2D4 XOR2D4

edit:
	klayout -nn $(PDK_KNFILE) -e -s $(GDS)

lvs: $(LVS_REPORTS)
	! grep -rwI "Netlists don't match" reports/

reports/%.lvsdb: $(GDS) $(SPICE)
	python3 $(ROOT_DIR)/lib/run_lvs.py --custom_deck=$(CELLS_DIR)/lvs/sg13g2_custom.lvs --layout=$(GDS) --netlist=$(SPICE) --run_dir=$(CELLS_DIR)/reports/ --topcell=sg13g2f_$* --run_mode=flat --verbose

cells_lef: $(GDS)
	cd $(CELLS_DIR)/reports/ && bash $(gds2lef_file) $(GDS) $(CELLS_DIR)/sg13g2f.port.csv $(PDK_FILE)

clean:
#	rm -rf *.lef
	rm -rf reports/*
#	rm -rf $(CELLS_LEFS)
