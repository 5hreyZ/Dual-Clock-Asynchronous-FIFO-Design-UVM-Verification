SIM ?= icarus
TOPLEVEL_LANG ?= verilog

EXTRA_ARGS += -g2012
COMPILE_ARGS += -g2012

VERILOG_SOURCES += $(PWD)/../rtl/sync_2ff.sv
VERILOG_SOURCES += $(PWD)/../rtl/fifo_mem.sv
VERILOG_SOURCES += $(PWD)/../rtl/wptr_full.sv
VERILOG_SOURCES += $(PWD)/../rtl/rptr_empty.sv
VERILOG_SOURCES += $(PWD)/../rtl/async_fifo.sv

TOPLEVEL = async_fifo
MODULE   = test_async_fifo

include $(shell cocotb-config --makefiles)/Makefile.sim
