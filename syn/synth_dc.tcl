# Synopsys Design Compiler (dc_shell) Synthesis Script

set target_library [list your_standard_cell_library.db]
set link_library   [list * your_standard_cell_library.db]

# Analyze SystemVerilog sources
analyze -format sverilog {
    ../rtl/sync_2ff.sv
    ../rtl/fifo_mem.sv
    ../rtl/wptr_full.sv
    ../rtl/rptr_empty.sv
    ../rtl/async_fifo.sv
}

elaborate async_fifo
current_design async_fifo
link

# Source SDC Timing Constraints
source -echo -verbose fifo_cdc.xdc

# Compile with high optimization effort
compile_ultra -no_autoungroup

# Generate Reports
report_area > report_area.rpt
report_timing > report_timing.rpt
report_power > report_power.rpt
report_clock_gating > report_clock_gating.rpt

# Write Gate-Level Netlist
write -format verilog -hierarchy -output netlist_dc.v
