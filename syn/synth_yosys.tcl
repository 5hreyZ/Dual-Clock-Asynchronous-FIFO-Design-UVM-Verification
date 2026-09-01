# Yosys Open-Source Synthesis Script for Asynchronous FIFO

# Read SystemVerilog RTL files
read_verilog -sv ../rtl/sync_2ff.sv
read_verilog -sv ../rtl/fifo_mem.sv
read_verilog -sv ../rtl/wptr_full.sv
read_verilog -sv ../rtl/rptr_empty.sv
read_verilog -sv ../rtl/async_fifo.sv

# Check design hierarchy
hierarchy -check -top async_fifo

# Generic synthesis optimization
synth -top async_fifo -flatten

# Clean and optimize
opt -full
opt_clean -purge

# Display cell and gate-level utilization statistics
stat

# Export synthesized structural netlist
write_verilog -noattr netlist_synth.v
