# AMD Xilinx Vivado Non-Project Batch Synthesis & CDC Analysis Script

# Set target device (e.g. Artix-7 or UltraScale+)
set_part xc7a35tcsg324-1

# Read SystemVerilog RTL sources
read_verilog -sv ../rtl/sync_2ff.sv
read_verilog -sv ../rtl/fifo_mem.sv
read_verilog -sv ../rtl/wptr_full.sv
read_verilog -sv ../rtl/rptr_empty.sv
read_verilog -sv ../rtl/async_fifo.sv

# Read CDC Timing Constraints
read_xdc fifo_cdc.xdc

# Run Out-Of-Context (OOC) Synthesis
synth_design -top async_fifo -part xc7a35tcsg324-1 -mode out_of_context

# Generate Utilization, Timing, and CDC Reports
report_utilization -file report_utilization.rpt
report_timing_summary -file report_timing.rpt
report_cdc -file report_cdc.rpt

# Export Synthesized Netlist & Checkpoint
write_verilog -force netlist_vivado.v
write_checkpoint -force async_fifo_synth.dcp

puts "========================================================"
puts " Vivado Synthesis & CDC Verification Completed Successfully!"
puts "========================================================"
