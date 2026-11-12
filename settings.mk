#######################################################
# Proportional dimmentions
ROOT_DIR?=$(abspath .)
# Technology: the float standard cells and the ADC cells are in cells/$(TECH) (cells/README.md)
TECH?=sg13g2f
CELLS_DIR?=$(ROOT_DIR)/cells/$(TECH)
# The SARADC_CELL_* wrappers mapped to the standard cells of TECH
CELL_DEF?=$(ROOT_DIR)/rtl/cell_def/$(TECH).v
# Results per technology: sg13g2f (the chip) keeps <stage>/outputs and <stage>/reports; the others
# use <stage>/outputs_<TECH> and <stage>/reports_<TECH> (like signoff/outputs_legacy), so a run of
# one technology never overwrites another (the parent chip reads pnr/outputs and signoff/outputs)
TECH_SFX=$(if $(filter sg13g2f,$(TECH)),,_$(TECH))
TECHS=sg13g2f sky130f gf180mcuf ics55f
# The logs of sg13g2f, without the ones of the other technologies (for its `make clean`)
SG13G2F_LOGS=$(filter-out $(foreach t,$(filter-out sg13g2f,$(TECHS)),%_$(t).log %_$(t).log.%),$(wildcard *.log*))
export TECH CELLS_DIR TECH_SFX

X=566.44
Y=361.08
# NOTE: Change Y at the moment of having a completed floorplan
# (X and Y are the die of the flat flow, pnr_legacy/, for 5 bits; the hierarchical flow, pnr/,
# computes its die from the macro)

#######################################################
# Number of bits of the ADC (2 to 8): `define NBITS of the RTL, nbits of the PnR, and the bit
# count of the simulation tools. Override with `make NBITS=8 ...` or the environment.
NBITS?=5
export NBITS
# The stamp changes when NBITS does, so that the synthesis (and everything after it) is redone
NBITS_STAMP:=$(ROOT_DIR)/.nbits$(TECH_SFX)
$(shell [ "$$(cat $(NBITS_STAMP) 2>/dev/null)" = "$(NBITS)" ] || echo $(NBITS) > $(NBITS_STAMP))

#######################################################
# Rules to create the files. 
# If there is no really rules, then can leave it blank
TOP=SARADC

SARADC_DIR=$(ROOT_DIR)
SYN_SRC?=$(ROOT_DIR)/rtl/cap.v \
$(ROOT_DIR)/rtl/cdac_dummy.v \
$(ROOT_DIR)/rtl/cdac_unit.v \
$(ROOT_DIR)/rtl/cdac.v \
$(CELL_DEF) \
$(ROOT_DIR)/rtl/comp.v \
$(ROOT_DIR)/rtl/saradc_analog.v \
$(ROOT_DIR)/rtl/sw.v \
$(ROOT_DIR)/rtl/sar_logic_buf.v \
$(ROOT_DIR)/rtl/saradc.v

#######################################################
# Hierarchical flow (pnr/): the CDAC half is a macro, placed twice
CDAC_TOP=SARADC_CDAC
CDAC_SRC?=$(ROOT_DIR)/rtl/cap.v \
$(ROOT_DIR)/rtl/cdac_dummy.v \
$(ROOT_DIR)/rtl/cdac_unit.v \
$(ROOT_DIR)/rtl/cdac.v \
$(CELL_DEF) \
$(ROOT_DIR)/rtl/sw.v \
$(ROOT_DIR)/rtl/hier/cdac_half.v
HIER_SRC?=$(CELL_DEF) \
$(ROOT_DIR)/rtl/comp.v \
$(ROOT_DIR)/rtl/sw.v \
$(ROOT_DIR)/rtl/sar_logic_buf.v \
$(ROOT_DIR)/rtl/hier/saradc_analog_hier.v \
$(ROOT_DIR)/rtl/hier/saradc_hier.v
# Read as blackboxes by the top synthesis
HIER_LIB_SRC?=$(ROOT_DIR)/rtl/hier/cdac_half.v

DIGTOP=sar_logic_wreset
SYN_DIG_SRC=$(ROOT_DIR)/rtl/sar_logic_wreset.v

#######################################################
# Rules to create the files. 
# If there is no really rules, then can leave it blank

PDK_ROOT?=/opt/ext/OpenPDKs/IHP-Open-PDK
PDK?=ihp-sg13g2
TECH_PDK=$(PDK_ROOT)/$(PDK)
PDK_FILE?=none
PDK_KFILE ?= $(TECH_PDK)/libs.tech/klayout/tech/sg13g2.lyp
