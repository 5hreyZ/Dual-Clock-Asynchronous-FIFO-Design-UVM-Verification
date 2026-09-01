//=============================================================================
// File: fifo_test_wrappers.sv
// Description: Non-parameterized UVM test wrappers for factory registration.
//              These allow UVM_TESTNAME=<name> to work from the command line
//              since parameterized classes get mangled factory names.
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_TEST_WRAPPERS_SV
`define FIFO_TEST_WRAPPERS_SV

// Default design parameters
localparam int DW = 8;
localparam int AW = 4;

class fifo_sanity_test_wrapper extends fifo_sanity_test #(DW, AW);
    `uvm_component_utils(fifo_sanity_test_wrapper)
    function new(string name = "fifo_sanity_test_wrapper", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

class fifo_burst_test_wrapper extends fifo_burst_test #(DW, AW);
    `uvm_component_utils(fifo_burst_test_wrapper)
    function new(string name = "fifo_burst_test_wrapper", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

class fifo_concurrent_test_wrapper extends fifo_concurrent_test #(DW, AW);
    `uvm_component_utils(fifo_concurrent_test_wrapper)
    function new(string name = "fifo_concurrent_test_wrapper", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

class fifo_overflow_underflow_test_wrapper extends fifo_overflow_underflow_test #(DW, AW);
    `uvm_component_utils(fifo_overflow_underflow_test_wrapper)
    function new(string name = "fifo_overflow_underflow_test_wrapper", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

class fifo_clock_ratio_test_wrapper extends fifo_clock_ratio_test #(DW, AW);
    `uvm_component_utils(fifo_clock_ratio_test_wrapper)
    function new(string name = "fifo_clock_ratio_test_wrapper", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

class fifo_random_stress_test_wrapper extends fifo_random_stress_test #(DW, AW);
    `uvm_component_utils(fifo_random_stress_test_wrapper)
    function new(string name = "fifo_random_stress_test_wrapper", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif // FIFO_TEST_WRAPPERS_SV
