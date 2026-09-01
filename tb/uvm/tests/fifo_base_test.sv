//=============================================================================
// File: fifo_base_test.sv
// Description: Base UVM Test creating environment and handling test lifecycles
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_BASE_TEST_SV
`define FIFO_BASE_TEST_SV

class fifo_base_test #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_test;

    `uvm_component_param_utils(fifo_base_test #(DATA_WIDTH, ADDR_WIDTH))

    fifo_env #(DATA_WIDTH, ADDR_WIDTH) env;

    function new(string name = "fifo_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        // Default drain time
        phase.phase_done.set_drain_time(this, 100ns);
    endtask

endclass

`endif // FIFO_BASE_TEST_SV
