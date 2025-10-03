ROOT_DIR=$(abspath ../)
include $(ROOT_DIR)/settings.mk
PNR_DIR=$(abspath .)
SYN_DIR=$(abspath ../syn)
RTL_DIR=$(abspath ../rtl)

export SYN_DIR
export PNR_DIR
export SYN_SRC
export RTL_DIR
export TOP
export ROOT_DIR
export X
export Y
export TECH
export PDK_ROOT

SYN_NET=$(SYN_DIR)/outputs/$(TOP)_net.v
export SYN_NET
SYN_DIG_NET=$(SYN_DIR)/outputs/$(DIGTOP)_net.v
export SYN_DIG_NET

all: $(PNR_DIR)/outputs/$(TOP).def

$(PNR_DIR)/outputs/$(TOP).def: $(SYN_NET) $(SYN_DIG_NET) $(PNR_DIR)/tcl/pnr.tcl
	openroad -exit $(PNR_DIR)/tcl/pnr.tcl | tee -a openroad.log

manual: $(SYN_NET) $(SYN_DIG_NET) $(PNR_DIR)/tcl/pnr.tcl
	openroad -gui $(PNR_DIR)/tcl/pnr.tcl

debug: $(SYN_NET) $(SYN_DIG_NET) $(PNR_DIR)/tcl/pnr.tcl
	gdb --args openroad -gui $(PNR_DIR)/tcl/pnr.tcl

clean:
	rm -vrf fv/ outputs reports *.size *.log DesignLib

.PHONY: all manual clean

