//=============================================================================
// File: fifo_sanity_test.sv
// Description: Basic sanity test performing sequential writes followed by reads
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_SANITY_TEST_SV
`define FIFO_SANITY_TEST_SV

class fifo_sanity_test #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

    `uvm_component_param_utils(fifo_sanity_test #(DATA_WIDTH, ADDR_WIDTH))

    function new(string name = "fifo_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_write_seq #(DATA_WIDTH) w_seq;
        fifo_read_seq  #(DATA_WIDTH) r_seq;

        phase.raise_objection(this, "Starting fifo_sanity_test");

        w_seq = fifo_write_seq #(DATA_WIDTH)::type_id::create("w_seq");
        r_seq = fifo_read_seq  #(DATA_WIDTH)::type_id::create("r_seq");

        // Write 10 items
        w_seq.num_transactions = 10;
        w_seq.start(env.write_agent.sequencer);

        #50ns; // Cross-clock settling

        // Read 10 items
        r_seq.num_transactions = 10;
        r_seq.start(env.read_agent.sequencer);

        #100ns;
        phase.drop_objection(this, "Completed fifo_sanity_test");
    endtask

endclass

`endif // FIFO_SANITY_TEST_SV
