`timescale 1ns / 1ps

//=============================================================================
// File: fifo_burst_test.sv
// Description: Burst test verifying full depth write and complete drain across multiple cycles
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_BURST_TEST_SV
`define FIFO_BURST_TEST_SV

class fifo_burst_test #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

    localparam int DEPTH = (1 << ADDR_WIDTH);
    `uvm_component_param_utils(fifo_burst_test #(DATA_WIDTH, ADDR_WIDTH))

    function new(string name = "fifo_burst_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_burst_write_seq #(DATA_WIDTH, DEPTH) bw_seq;
        fifo_burst_read_seq  #(DATA_WIDTH, DEPTH) br_seq;

        phase.raise_objection(this, "Starting fifo_burst_test");

        bw_seq = fifo_burst_write_seq #(DATA_WIDTH, DEPTH)::type_id::create("bw_seq");
        br_seq = fifo_burst_read_seq  #(DATA_WIDTH, DEPTH)::type_id::create("br_seq");

        // Repeat burst fill & drain 3 times
        repeat (3) begin
            bw_seq.start(env.write_agent.sequencer);
            #100ns;
            br_seq.start(env.read_agent.sequencer);
            #100ns;
        end

        phase.drop_objection(this, "Completed fifo_burst_test");
    endtask

endclass

`endif // FIFO_BURST_TEST_SV
