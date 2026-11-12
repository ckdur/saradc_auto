ROOT_DIR=$(abspath ..)
SHELL=/bin/bash
.SHELLFLAGS=-o pipefail -c
include $(ROOT_DIR)/settings.mk
SYN_DIR=$(abspath .)

export SYN_DIR
export SYN_SRC
export TOP
export DIGTOP
export SYN_DIG_SRC
export ROOT_DIR
export TECH

# outputs/ for sg13g2f, outputs_<TECH> for the others (settings.mk)
SYN_OUT=$(SYN_DIR)/outputs$(TECH_SFX)
SYN_ANA_NET=$(SYN_OUT)/$(TOP)_net.v
SYN_NET=$(SYN_OUT)/$(DIGTOP)_net.v
export SYN_ANA_NET SYN_OUT

all: $(SYN_ANA_NET) $(SYN_NET)

# Hierarchical flow (pnr/): the CDAC macro and the top that instantiates it
HIER_DIR=$(SYN_OUT)/hier
hier: $(HIER_DIR)/$(CDAC_TOP)_net.v $(HIER_DIR)/$(TOP)_net.v $(SYN_NET)

$(HIER_DIR)/$(CDAC_TOP)_net.v: $(SYN_DIR)/tcl/synthesis_analog.tcl $(CDAC_SRC) $(NBITS_STAMP)
	TOP=$(CDAC_TOP) SYN_SRC="$(CDAC_SRC)" SYN_OUT_DIR=$(HIER_DIR) \
	  yosys -h tcl $(SYN_DIR)/tcl/synthesis_analog.tcl | tee yosys_$(CDAC_TOP)$(TECH_SFX).log

$(HIER_DIR)/$(TOP)_net.v: $(SYN_DIR)/tcl/synthesis_analog.tcl $(HIER_SRC) $(HIER_LIB_SRC) $(NBITS_STAMP)
	SYN_SRC="$(HIER_SRC)" SYN_LIB_SRC="$(HIER_LIB_SRC)" SYN_OUT_DIR=$(HIER_DIR) \
	  yosys -h tcl $(SYN_DIR)/tcl/synthesis_analog.tcl | tee yosys_hier$(TECH_SFX).log

$(SYN_ANA_NET): $(SYN_DIR)/tcl/synthesis_analog.tcl $(SYN_SRC) $(NBITS_STAMP)
	yosys -h tcl $(SYN_DIR)/tcl/synthesis_analog.tcl | tee -a yosys_analog$(TECH_SFX).log

$(SYN_NET): $(SYN_DIR)/tcl/synthesis.tcl $(SYN_DIG_SRC) $(NBITS_STAMP)
	yosys -h tcl $(SYN_DIR)/tcl/synthesis.tcl | tee -a yosys$(TECH_SFX).log

# Generating only the analog netlist (for subcircuits)
gen: $(SYN_ANA_NET) $(SYN_DIR)/tcl/netlist.tcl
	openroad -exit $(SYN_DIR)/tcl/netlist.tcl | tee -a openroad.log

manual: $(SYN_DIR)/tcl/synthesis.tcl $(SYN_SRC)
	yosys -h tcl

# Removes the results of TECH only
clean:
ifeq ($(TECH_SFX),)
	rm -rfv $(SG13G2F_LOGS) *.cmd* *_intermediate.v *_net.v *.sdf fv reports outputs *.tstamp
else
	rm -rfv *$(TECH_SFX).log* reports$(TECH_SFX) outputs$(TECH_SFX) logs$(TECH_SFX)
endif

.PHONY: clean hier

