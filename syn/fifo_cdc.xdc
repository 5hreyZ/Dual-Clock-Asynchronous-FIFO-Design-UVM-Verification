# Timing and CDC Constraints for Dual-Clock Asynchronous FIFO
# Target: AMD Xilinx Vivado / Synopsys Design Compiler

# 1. Define Primary Independent Clocks
create_clock -name wclk -period 10.000 [get_ports wclk]  # 100 MHz Write Clock
create_clock -name rclk -period 25.000 [get_ports rclk]  # 40 MHz Read Clock

# 2. Declare Independent Asynchronous Clock Groups
# Instructs STA (Static Timing Analysis) that no synchronous phase relationship exists
set_clock_groups -asynchronous \
    -group [get_clocks wclk] \
    -group [get_clocks rclk]

# 3. Constrain Maximum Delay on Domain-Crossing Gray Pointer Paths
# Max delay is bounded by the destination clock period to prevent bus skew
set_max_delay -from [get_cells -hier *rptr_gray*] \
              -to   [get_cells -hier *u_sync_r2w*sync_regs_reg[0]*] \
              -datapath_only 10.000

set_max_delay -from [get_cells -hier *wptr_gray*] \
              -to   [get_cells -hier *u_sync_w2r*sync_regs_reg[0]*] \
              -datapath_only 25.000

# 4. Asynchronous Reset Constraints
set_false_path -from [get_ports wrst_n]
set_false_path -from [get_ports rrst_n]
