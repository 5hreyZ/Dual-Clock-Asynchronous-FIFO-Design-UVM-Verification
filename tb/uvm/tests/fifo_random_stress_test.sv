`timescale 1ns / 1ps

//=============================================================================
// File: fifo_random_stress_test.sv
// Description: Full randomized stress test testing all data patterns and delays
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_RANDOM_STRESS_TEST_SV
`define FIFO_RANDOM_STRESS_TEST_SV

class fifo_random_stress_test #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

    `uvm_component_param_utils(fifo_random_stress_test #(DATA_WIDTH, ADDR_WIDTH))

    function new(string name = "fifo_random_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_write_seq #(DATA_WIDTH) w_seq_rand, w_seq_w1, w_seq_w0, w_seq_aa;
        fifo_read_seq  #(DATA_WIDTH) r_seq;

        phase.raise_objection(this, "Starting fifo_random_stress_test");

        // Phase 1: Walking 1s and 0s
        w_seq_w1 = fifo_write_seq #(DATA_WIDTH)::type_id::create("w_seq_w1");
        w_seq_w1.num_transactions = 20;
        w_seq_w1.pattern = PAT_WALKING_1S;

        w_seq_w0 = fifo_write_seq #(DATA_WIDTH)::type_id::create("w_seq_w0");
        w_seq_w0.num_transactions = 20;
        w_seq_w0.pattern = PAT_WALKING_0S;

        w_seq_aa = fifo_write_seq #(DATA_WIDTH)::type_id::create("w_seq_aa");
        w_seq_aa.num_transactions = 20;
        w_seq_aa.pattern = PAT_ALT_BITS;

        w_seq_rand = fifo_write_seq #(DATA_WIDTH)::type_id::create("w_seq_rand");
        w_seq_rand.num_transactions = 100;
        w_seq_rand.pattern = PAT_RANDOM;

        r_seq = fifo_read_seq #(DATA_WIDTH)::type_id::create("r_seq");
        r_seq.num_transactions = 160;

        fork
            begin
                w_seq_w1.start(env.write_agent.sequencer);
                w_seq_w0.start(env.write_agent.sequencer);
                w_seq_aa.start(env.write_agent.sequencer);
                w_seq_rand.start(env.write_agent.sequencer);
            end
            begin
                #10ns;
                r_seq.start(env.read_agent.sequencer);
            end
        join

        #500ns;
        phase.drop_objection(this, "Completed fifo_random_stress_test");
    endtask

endclass

`endif // FIFO_RANDOM_STRESS_TEST_SV
