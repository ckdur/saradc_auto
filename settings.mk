#######################################################
# Proportional dimmentions
ROOT_DIR?=$(abspath .)
TECH?=sg13g2f

X=566.44
Y=361.08
# NOTE: Change Y at the moment of having a completed floorplan

#######################################################
# Rules to create the files. 
# If there is no really rules, then can leave it blank
TOP=SARADC

SARADC_DIR=$(ROOT_DIR)
SYN_SRC?=$(ROOT_DIR)/rtl/cap.v \
$(ROOT_DIR)/rtl/cdac_dummy.v \
$(ROOT_DIR)/rtl/cdac_unit.v \
$(ROOT_DIR)/rtl/cdac.v \
$(ROOT_DIR)/rtl/cell_def.v \
$(ROOT_DIR)/rtl/comp.v \
$(ROOT_DIR)/rtl/saradc_analog.v \
$(ROOT_DIR)/rtl/sw.v \
$(ROOT_DIR)/rtl/sar_logic_buf.v \
$(ROOT_DIR)/rtl/saradc.v

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
