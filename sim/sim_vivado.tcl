#=============================================================================
# File: sim_vivado.tcl
# Description: Vivado Simulation & Waveform Generation Script
#=============================================================================

# 1. Create in-memory simulation project
create_project -force fifo_sim ./vivado_sim -part xc7a35tcsg324-1

# 2. Add Synthesizable RTL & SVA Source Files
add_files -fileset sources_1 [list \
    ../rtl/sync_2ff.sv \
    ../rtl/fifo_mem.sv \
    ../rtl/wptr_full.sv \
    ../rtl/rptr_empty.sv \
    ../rtl/async_fifo.sv \
    ../sva/fifo_sva.sv \
    ../sva/fifo_bind.sv \
]

# 3. Add Testbench Files
add_files -fileset sim_1 [list \
    ../tb/fifo_if.sv \
    ../tb/uvm/fifo_pkg.sv \
    ../tb/tb_top.sv \
]

# 4. Set Include Directories
set_property include_dirs [list ../rtl ../sva ../tb ../tb/uvm] [get_filesets sources_1]
set_property include_dirs [list ../rtl ../sva ../tb ../tb/uvm] [get_filesets sim_1]

# 5. Set Top Module
set_property top tb_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# 6. Pass -L uvm to xelab using the "--" end-of-options flag so -L is not parsed as a Vivado switch
set_property -- xsim.elaborate.xelab.more_options {-L uvm} [get_filesets sim_1]

# 7. Launch Simulation GUI
launch_simulation

# 8. Add Key Signals to Wave Window
add_wave /tb_top/wclk
add_wave /tb_top/dut_if/wrst_n
add_wave /tb_top/dut_if/w_inc
add_wave /tb_top/dut_if/wdata
add_wave /tb_top/dut_if/wfull
add_wave /tb_top/dut_if/almost_full
add_wave /tb_top/u_dut/wptr_gray
add_wave /tb_top/u_dut/rptr_gray_sync

add_wave /tb_top/rclk
add_wave /tb_top/dut_if/rrst_n
add_wave /tb_top/dut_if/r_inc
add_wave /tb_top/dut_if/rdata
add_wave /tb_top/dut_if/rempty
add_wave /tb_top/dut_if/almost_empty
add_wave /tb_top/u_dut/rptr_gray
add_wave /tb_top/u_dut/wptr_gray_sync

# 9. Run for 2000ns
run 2000ns
