# Synthesis Makefile for Dual-Clock Asynchronous FIFO
# Supports: Yosys (Local/Open-Source), Vivado (Xilinx), Design Compiler (Synopsys)

all: help

help:
	@echo "=============================================================="
	@echo " Async FIFO Synthesis Makefile"
	@echo "=============================================================="
	@echo " Available Targets:"
	@echo "   make yosys   - Synthesize using Yosys open-source flow"
	@echo "   make vivado  - Synthesize & run report_cdc with AMD Vivado"
	@echo "   make dc      - Synthesize with Synopsys Design Compiler"
	@echo "   make clean   - Remove generated netlists and reports"
	@echo "=============================================================="

yosys:
	yosys -s synth_yosys.tcl | tee synth_yosys.log

vivado:
	vivado -mode batch -source synth_vivado.tcl -nojournal -nolog

dc:
	dc_shell -f synth_dc.tcl | tee synth_dc.log

clean:
	rm -rf *.log *.rpt *.v *.dcp .Xil netlist_*
