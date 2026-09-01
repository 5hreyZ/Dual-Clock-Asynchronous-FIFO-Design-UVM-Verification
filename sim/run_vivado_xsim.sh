#!/bin/bash
# Direct Vivado Simulator (xsim) compilation and GUI launcher
set -e

mkdir -p vivado_sim
cd vivado_sim

echo "== 1. Compiling SystemVerilog Design and Testbench =="
xvlog -sv -L uvm -i ../../rtl -i ../../sva -i ../../tb -i ../../tb/uvm \
    ../../rtl/sync_2ff.sv \
    ../../rtl/fifo_mem.sv \
    ../../rtl/wptr_full.sv \
    ../../rtl/rptr_empty.sv \
    ../../rtl/async_fifo.sv \
    ../../sva/fifo_sva.sv \
    ../../sva/fifo_bind.sv \
    ../../tb/fifo_if.sv \
    ../../tb/uvm/fifo_pkg.sv \
    ../../tb/tb_top.sv

echo "== 2. Elaborating Top Level Design =="
xelab -top tb_top -L uvm -debug typical -s fifo_top_sim

echo "== 3. Launching Vivado Waveform GUI =="
xsim fifo_top_sim -gui
