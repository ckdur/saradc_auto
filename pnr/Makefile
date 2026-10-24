ROOT_DIR=$(abspath ../)
SHELL=/bin/bash
.SHELLFLAGS=-o pipefail -c
include $(ROOT_DIR)/settings.mk
PNR_DIR=$(abspath .)
SYN_DIR=$(abspath ../syn)
HIER_DIR=$(SYN_DIR)/outputs/hier

# Hierarchical PnR: the CDAC half (SARADC_CDAC) is a macro, the top (SARADC)
# places it twice. The procedures are the ones of the flat flow (pnr_legacy/tcl).
export ROOT_DIR PNR_DIR SYN_DIR TECH PDK_ROOT X

CDAC_DEF=$(PNR_DIR)/outputs/$(CDAC_TOP).def
TOP_DEF=$(PNR_DIR)/outputs/$(TOP).def

all: cdac top

cdac: $(CDAC_DEF)

top: $(TOP_DEF)

$(CDAC_DEF): $(HIER_DIR)/$(CDAC_TOP)_net.v $(PNR_DIR)/tcl/cdac.tcl $(PNR_DIR)/tcl/setup.tcl
	TOP=$(CDAC_TOP) NETLISTS="$<" openroad -exit $(PNR_DIR)/tcl/cdac.tcl | tee $(CDAC_TOP).log

$(TOP_DEF): $(HIER_DIR)/$(TOP)_net.v $(SYN_DIR)/outputs/$(DIGTOP)_net.v $(CDAC_DEF) $(PNR_DIR)/tcl/top.tcl $(PNR_DIR)/tcl/setup.tcl
	TOP=$(TOP) NETLISTS="$(HIER_DIR)/$(TOP)_net.v $(SYN_DIR)/outputs/$(DIGTOP)_net.v" \
	  MACROS="$(CDAC_TOP)" openroad -exit $(PNR_DIR)/tcl/top.tcl | tee $(TOP).log

manual_cdac: $(HIER_DIR)/$(CDAC_TOP)_net.v
	TOP=$(CDAC_TOP) NETLISTS="$<" openroad -gui $(PNR_DIR)/tcl/cdac.tcl

clean:
	rm -vrf outputs reports *.size *.log DesignLib*

.PHONY: all cdac top manual_cdac clean
