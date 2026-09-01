//=============================================================================
// File: fifo_concurrent_test.sv
// Description: Concurrent read & write test simulating simultaneous cross-domain traffic
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_CONCURRENT_TEST_SV
`define FIFO_CONCURRENT_TEST_SV

class fifo_concurrent_test #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

    `uvm_component_param_utils(fifo_concurrent_test #(DATA_WIDTH, ADDR_WIDTH))

    function new(string name = "fifo_concurrent_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_write_seq #(DATA_WIDTH) w_seq;
        fifo_read_seq  #(DATA_WIDTH) r_seq;

        phase.raise_objection(this, "Starting fifo_concurrent_test");

        w_seq = fifo_write_seq #(DATA_WIDTH)::type_id::create("w_seq");
        r_seq = fifo_read_seq  #(DATA_WIDTH)::type_id::create("r_seq");

        w_seq.num_transactions = 50;
        r_seq.num_transactions = 50;

        // Run write and read simultaneously
        fork
            w_seq.start(env.write_agent.sequencer);
            begin
                #20ns; // Slight offset to allow first item in
                r_seq.start(env.read_agent.sequencer);
            end
        join

        #200ns;
        phase.drop_objection(this, "Completed fifo_concurrent_test");
    endtask

endclass

`endif // FIFO_CONCURRENT_TEST_SV
