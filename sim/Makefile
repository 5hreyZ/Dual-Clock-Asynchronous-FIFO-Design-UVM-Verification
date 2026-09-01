#==============================================================================
# Makefile for Dual-Clock Asynchronous FIFO UVM Verification Environment
# Supported Simulators: Synopsys VCS, Siemens Questa/ModelSim, Cadence Xcelium
#==============================================================================

# Default Settings
TEST       ?= fifo_sanity_test
VERBOSITY  ?= UVM_LOW
SEED       ?= random
WCLK_HP    ?= 5.0
RCLK_HP    ?= 12.5

# Directories
RTL_DIR    = ../rtl
TB_DIR     = ../tb
SVA_DIR    = ../sva

# Simulator Flags
VCS_FLAGS   = -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -kdb -debug_access+all \
              -assert svaext +vpi +incdir+$(RTL_DIR)+$(TB_DIR)+$(TB_DIR)/uvm+$(SVA_DIR) \
              -cm line+cond+fsm+tgl+branch+assert

QUESTA_FLAGS = -sv -timescale 1ns/1ps -suppress 12003,2182 \
               +incdir+$(RTL_DIR)+$(TB_DIR)+$(TB_DIR)/uvm+$(SVA_DIR)

XCELIUM_FLAGS = -64bit -sv -uvm -uvmhome CDNS-1.2 -timescale 1ns/1ps \
                -access +rwc -coverage all \
                +incdir+$(RTL_DIR)+$(TB_DIR)+$(TB_DIR)/uvm+$(SVA_DIR)

# Default target
all: run_vcs

help:
	@echo "======================================================================"
	@echo " Dual-Clock Async FIFO UVM Simulation Makefile"
	@echo "======================================================================"
	@echo " Available Targets:"
	@echo "   make run_vcs     TEST=<test_name>  - Compile & run with Synopsys VCS"
	@echo "   make run_questa  TEST=<test_name>  - Compile & run with Siemens Questa"
	@echo "   make run_xcelium TEST=<test_name>  - Compile & run with Cadence Xcelium"
	@echo "   make run_all                       - Run full regression suite"
	@echo "   make view_waves                    - Open waveform viewer"
	@echo "   make clean                         - Remove all simulation artifacts"
	@echo ""
	@echo " Available Tests:"
	@echo "   - fifo_sanity_test"
	@echo "   - fifo_burst_test"
	@echo "   - fifo_concurrent_test"
	@echo "   - fifo_overflow_underflow_test"
	@echo "   - fifo_clock_ratio_test"
	@echo "   - fifo_random_stress_test"
	@echo "======================================================================"

# -----------------------------------------------------------------------------
# Synopsys VCS Flow
# -----------------------------------------------------------------------------
comp_vcs:
	vcs $(VCS_FLAGS) -f filelist_rtl.f -f filelist_tb.f -top tb_top -l comp.log

run_vcs: comp_vcs
	./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +ntb_random_seed=$(SEED) \
	      +WCLK_HP=$(WCLK_HP) +RCLK_HP=$(RCLK_HP) -l run.log

# -----------------------------------------------------------------------------
# Siemens Questa Flow
# -----------------------------------------------------------------------------
comp_questa:
	vlib work
	vlog $(QUESTA_FLAGS) -f filelist_rtl.f -f filelist_tb.f -l comp.log

run_questa: comp_questa
	vsim -c -do "run -all; exit;" tb_top +UVM_TESTNAME=$(TEST) \
	     +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	     +WCLK_HP=$(WCLK_HP) +RCLK_HP=$(RCLK_HP) -l run.log

# -----------------------------------------------------------------------------
# Cadence Xcelium Flow
# -----------------------------------------------------------------------------
run_xcelium:
	xrun $(XCELIUM_FLAGS) -f filelist_rtl.f -f filelist_tb.f -top tb_top \
	     +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -svseed $(SEED) \
	     +WCLK_HP=$(WCLK_HP) +RCLK_HP=$(RCLK_HP) -l run.log

# -----------------------------------------------------------------------------
# Full Regression Target
# -----------------------------------------------------------------------------
TESTS = fifo_sanity_test fifo_burst_test fifo_concurrent_test fifo_overflow_underflow_test fifo_clock_ratio_test fifo_random_stress_test

run_all:
	@for t in $(TESTS); do \
		echo "============================================================"; \
		echo " RUNNING TEST: $$t "; \
		echo "============================================================"; \
		$(MAKE) run_vcs TEST=$$t VERBOSITY=UVM_LOW || exit 1; \
	done

# -----------------------------------------------------------------------------
# Waveform Viewing
# -----------------------------------------------------------------------------
view_waves:
	@which gtkwave > /dev/null 2>&1 && gtkwave dump.vcd || \
	 which verdi > /dev/null 2>&1 && verdi -ssf dump.fsdb || \
	 echo "No waveform viewer found (gtkwave / verdi)"

# -----------------------------------------------------------------------------
# Clean
# -----------------------------------------------------------------------------
clean:
	rm -rf csrc simv* *.log *.key *.vpd *.vcd *.fsdb DVEfiles verdiLog work transcript \
	       xcelium.d waves.shm cov_work *.vstf *.dat .simvision
