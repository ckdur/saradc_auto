
ROOT_DIR=$(abspath ../)
include $(ROOT_DIR)/settings.mk
SIM_DIR=$(abspath .)
SYN_DIR=$(abspath ../syn)

TB_ANA_SRC=$(ROOT_DIR)/src/saradc_tb.sp
CDL_SRC=$(ROOT_DIR)/pnr/outputs/$(TOP).cdl

TB_ANA_XYCE_SRC=$(ROOT_DIR)/src/saradc_tb.xyce.sp
CDL_XYCE_SRC=$(SIM_DIR)/outputs/$(TOP).xyce.ckt

# For now, just using the LVS result.
# Replace me with the actual RCX when ready
TB_RCX_SRC=$(ROOT_DIR)/src/saradc_tb_rcx.sp
RCX_SRC=$(ROOT_DIR)/signoff/results/$(TOP).cir

# The fclk stuff we want
FREQS=100000000 50000000 200000000
CORNER=mos_tt
TRAN_DATAS=$(FREQS:%=$(SIM_DIR)/outputs/saradc_tb.xyce.%.csv)
TRAN_PDFS=$(FREQS:%=$(SIM_DIR)/outputs/saradc_tb.xyce.%.pdf)

XYCE_RUN_COMMAND=Xyce -plugin $(PDK_ROOT)/$(PDK)/libs.tech/xyce/plugins/libXyce_Plugin_PSP103_VA.so,$(PDK_ROOT)/$(PDK)/libs.tech/xyce/plugins/libXyce_Plugin_r3_cmc.so

TB_SRC=$(ROOT_DIR)/rtl/sar_logic_tb.v
VER_SIM_SRC=$(ROOT_DIR)/rtl/$(DIGTOP).v
SYN_SIM_SRC=$(ROOT_DIR)/syn/outputs/$(DIGTOP)_net.v

ana: $(SIM_DIR)/outputs/saradc_tb.csv

viewana: $(SIM_DIR)/outputs/saradc_tb.csv $(SIM_DIR)/scripts/plot.vin_vout.gnu $(SIM_DIR)/scripts/plot.result.gnu
	gnuplot -c $(SIM_DIR)/scripts/plot.vin_vout.gnu $(SIM_DIR)/outputs/saradc_tb.csv $(SIM_DIR)/outputs/saradc_tb.vin_vout.pdf "Vin vs Vout"
	gnuplot -c $(SIM_DIR)/scripts/plot.result.gnu $(SIM_DIR)/outputs/saradc_tb.csv $(SIM_DIR)/outputs/saradc_tb.result.pdf "Results"

#ana2: $(SIM_DIR)/outputs/saradc_tb.xyce.csv
ana2: $(TRAN_DATAS)

viewana2: $(TRAN_PDFS)


rcx: $(SIM_DIR)/outputs/saradc_tb_rcx.csv

sim: $(SIM_DIR)/outputs/sar_logic_tb.vcd

syn: $(SIM_DIR)/outputs/sar_logic_tb_syn.vcd


# Simulation commands
$(SIM_DIR)/outputs/saradc_tb.csv: $(TB_ANA_SRC) $(CDL_SRC)
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs/ && ngspice $(TB_ANA_SRC) -r $(SIM_DIR)/outputs/$(TOP).raw --soa-log=$(SIM_DIR)/outputs/$(TOP).soa.log

$(CDL_XYCE_SRC): $(CDL_SRC)
	mkdir -p $(SIM_DIR)/outputs
	sed 's/SARADC_FILL1_NOPOWER/dummynet SARADC_FILL1_NOPOWER/' $(CDL_SRC) > $(CDL_XYCE_SRC)

DEPS=$(SIM_DIR)/outputs/SARADC_CELL_INVX16_ASCAP.ckt
$(DEPS): $(ROOT_DIR)/cells/SARADC_CELL_INVX16_ASCAP.ckt
	mkdir -p $(SIM_DIR)/outputs
	cp $(ROOT_DIR)/cells/*.ckt $(SIM_DIR)/outputs
	cp $(ROOT_DIR)/cells/*.cdl $(SIM_DIR)/outputs

$(SIM_DIR)/outputs/saradc_tb.xyce.%.csv: $(TB_ANA_XYCE_SRC) $(CDL_XYCE_SRC) $(DEPS)
	cp $(TB_ANA_XYCE_SRC) $(SIM_DIR)/outputs/saradc_tb.$*.sp
	cp $(ROOT_DIR)/src/saradc_tb_body.sp $(SIM_DIR)/outputs
	cp $(ROOT_DIR)/src/dac_r2r_ideal.sp $(SIM_DIR)/outputs
	sed -i -e 's/{DEF_FCLK}/$*/g ; s/saradc_tb.xyce/saradc_tb.xyce.$*/g ; s/mos_tt/$(CORNER)/g ; s|{PDK_ROOT}|$(PDK_ROOT)|g ; s|{PDK}|$(PDK)|g' $(SIM_DIR)/outputs/saradc_tb.$*.sp
	cd $(SIM_DIR)/outputs/ && mpirun $(XYCE_RUN_COMMAND) $(SIM_DIR)/outputs/saradc_tb.$*.sp | tee $(SIM_DIR)/outputs/saradc_tb.$*.log

$(SIM_DIR)/outputs/saradc_tb.xyce.%.pdf: $(SIM_DIR)/outputs/saradc_tb.xyce.%.csv $(SIM_DIR)/scripts/plot.vin_vout.xyce.gnu $(SIM_DIR)/scripts/plot.result.xyce.gnu
	gnuplot -c $(SIM_DIR)/scripts/plot.vin_vout.xyce.gnu $(SIM_DIR)/outputs/saradc_tb.xyce.$*.csv $(SIM_DIR)/outputs/saradc_tb.vin_vout.xyce.$*.pdf "Vin vs Vout"
	gnuplot -c $(SIM_DIR)/scripts/plot.result.xyce.gnu $(SIM_DIR)/outputs/saradc_tb.xyce.$*.csv $(SIM_DIR)/outputs/saradc_tb.result.xyce.$*.pdf "Results"

test_cap_linearity: $(ROOT_DIR)/src/cap_linearity.xyce.sp $(CDL_XYCE_SRC) $(DEPS)
	python3 $(ROOT_DIR)/src/cap_extract.py $(SIM_DIR)/outputs $(ROOT_DIR)/src/cap_linearity.xyce.sp "$(XYCE_RUN_COMMAND)"

CHARGE_INJECTION_DEPS=$(SIM_DIR)/outputs/SARADC_SW.cdl $(SIM_DIR)/outputs/SARADC_SWDUM.cdl

$(SIM_DIR)/outputs/%.cdl: $(SYN_DIR)/Makefile
	make -C $(SYN_DIR) gen TOP=$*
	cp $(SYN_DIR)/outputs/$*.cdl $@

test_sw_charge_injection: $(ROOT_DIR)/src/sw_charge_injection.xyce.sp $(CDL_XYCE_SRC) $(DEPS) $(CHARGE_INJECTION_DEPS)
	cp $(ROOT_DIR)/src/sw_classic.sp $(SIM_DIR)/outputs
	cp $(ROOT_DIR)/src/sw_load.sp $(SIM_DIR)/outputs
	python3 $(ROOT_DIR)/src/sw_charge_injection.py $(SIM_DIR)/outputs $(ROOT_DIR)/src/sw_charge_injection.xyce.sp "$(XYCE_RUN_COMMAND)"

$(SIM_DIR)/outputs/saradc_tb_rcx.csv: $(TB_RCX_SRC) $(RCX_SRC)
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs/ && ngspice $(TB_RCX_SRC) -r $(SIM_DIR)/outputs/$(TOP)_rcx.raw --soa-log=$(SIM_DIR)/outputs/$(TOP)_rcx.soa.log

$(SIM_DIR)/outputs/sar_logic_tb.vcd: $(TB_SRC) $(VER_SIM_SRC)
	mkdir -p $(SIM_DIR)/outputs
	iverilog -D DIGTOP=$(DIGTOP) -s sar_logic_tb -o $(SIM_DIR)/outputs/$(TOP).o $(TB_SRC) $(VER_SIM_SRC)
	cd $(SIM_DIR)/outputs && $(SIM_DIR)/outputs/$(TOP).o

$(SIM_DIR)/outputs/sar_logic_tb_syn.vcd: $(TB_SRC) $(SYN_SIM_SRC)
	mkdir -p $(SIM_DIR)/outputs
	iverilog -D DIGTOP=$(DIGTOP) -D SYNTHESIS=1 -m sar_logic_tb -o $(SIM_DIR)/outputs/$(TOP)_syn.o $(TB_SRC) $(SYN_SIM_SRC) $(ROOT_DIR)/cells/sg13g2f.v
	cd $(SIM_DIR)/outputs && $(SIM_DIR)/outputs/$(TOP)_syn.o

clean:
	rm -rfv *.log* *.ic* *.tr* *.su* *.mt* *.st* *.pa* outputs

viewsim: $(SIM_DIR)/outputs/sar_logic_tb.vcd
	gtkwave $(SIM_DIR)/outputs/sar_logic_tb.vcd

viewsyn: $(SIM_DIR)/outputs/sar_logic_tb_syn.vcd
	gtkwave $(SIM_DIR)/outputs/sar_logic_tb_syn.vcd

question:
	mkdir -p $(SIM_DIR)/question/
	mkdir -p $(SIM_DIR)/question/pnr/outputs/
	mkdir -p $(SIM_DIR)/question/sim
	mkdir -p $(SIM_DIR)/question/cells
	cp -r $(ROOT_DIR)/pnr/outputs/$(TOP).cdl $(SIM_DIR)/question/pnr/outputs/
	cp -r $(ROOT_DIR)/sim/Makefile $(SIM_DIR)/question/sim
	cp -r $(ROOT_DIR)/sim/scripts $(SIM_DIR)/question/sim
	cp -r $(ROOT_DIR)/src $(SIM_DIR)/question
	cp -r $(ROOT_DIR)/cells/*.ckt $(SIM_DIR)/question/cells
	cp -r $(ROOT_DIR)/cells/*.cdl $(SIM_DIR)/question/cells
	cp -r $(ROOT_DIR)/settings.mk $(SIM_DIR)/question/

.PHONY: clean

