ROOT_DIR=$(abspath ../)
SHELL=/bin/bash
.SHELLFLAGS=-o pipefail -c
include $(ROOT_DIR)/settings.mk
PNR_DIR=$(abspath .)
SYN_DIR=$(abspath ../syn)
# outputs/ for sg13g2f, outputs_<TECH> for the others (settings.mk)
SYN_OUT=$(SYN_DIR)/outputs$(TECH_SFX)
HIER_DIR=$(SYN_OUT)/hier
PNR_OUT=$(PNR_DIR)/outputs$(TECH_SFX)

# Hierarchical PnR: the CDAC half (SARADC_CDAC) is a macro, the top (SARADC)
# places it twice. The procedures are the ones of the flat flow (pnr_legacy/tcl).
export ROOT_DIR PNR_DIR SYN_DIR TECH TECH_SFX PDK_ROOT X

CDAC_DEF=$(PNR_OUT)/$(CDAC_TOP).def
TOP_DEF=$(PNR_OUT)/$(TOP).def

all: cdac top

cdac: $(CDAC_DEF)

top: $(TOP_DEF)

$(CDAC_DEF): $(HIER_DIR)/$(CDAC_TOP)_net.v $(PNR_DIR)/tcl/cdac.tcl $(PNR_DIR)/tcl/setup.tcl
	TOP=$(CDAC_TOP) NETLISTS="$<" openroad -exit $(PNR_DIR)/tcl/cdac.tcl | tee $(CDAC_TOP)$(TECH_SFX).log

$(TOP_DEF): $(HIER_DIR)/$(TOP)_net.v $(SYN_OUT)/$(DIGTOP)_net.v $(CDAC_DEF) $(PNR_DIR)/tcl/top.tcl $(PNR_DIR)/tcl/setup.tcl
	TOP=$(TOP) NETLISTS="$(HIER_DIR)/$(TOP)_net.v $(SYN_OUT)/$(DIGTOP)_net.v" \
	  MACROS="$(CDAC_TOP)" openroad -exit $(PNR_DIR)/tcl/top.tcl | tee $(TOP)$(TECH_SFX).log

manual_cdac: $(HIER_DIR)/$(CDAC_TOP)_net.v
	TOP=$(CDAC_TOP) NETLISTS="$<" openroad -gui $(PNR_DIR)/tcl/cdac.tcl

# Removes the results of TECH only
clean:
ifeq ($(TECH_SFX),)
	rm -vrf outputs reports FPlanFinal.size $(SG13G2F_LOGS) DesignLib*
else
	rm -vrf outputs$(TECH_SFX) reports$(TECH_SFX) FPlanFinal$(TECH_SFX).size *$(TECH_SFX).log
endif

.PHONY: all cdac top manual_cdac clean
