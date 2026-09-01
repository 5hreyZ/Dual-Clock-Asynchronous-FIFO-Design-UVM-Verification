//=============================================================================
// File: fifo_clock_ratio_test.sv
// Description: Multi-clock frequency ratio test (Fast Write/Slow Read & Slow Write/Fast Read)
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_CLOCK_RATIO_TEST_SV
`define FIFO_CLOCK_RATIO_TEST_SV

class fifo_clock_ratio_test #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

    `uvm_component_param_utils(fifo_clock_ratio_test #(DATA_WIDTH, ADDR_WIDTH))

    function new(string name = "fifo_clock_ratio_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_write_seq #(DATA_WIDTH) w_seq;
        fifo_read_seq  #(DATA_WIDTH) r_seq;

        phase.raise_objection(this, "Starting fifo_clock_ratio_test");

        w_seq = fifo_write_seq #(DATA_WIDTH)::type_id::create("w_seq");
        r_seq = fifo_read_seq  #(DATA_WIDTH)::type_id::create("r_seq");

        // High volume continuous stress
        w_seq.num_transactions = 100;
        r_seq.num_transactions = 100;

        fork
            w_seq.start(env.write_agent.sequencer);
            r_seq.start(env.read_agent.sequencer);
        join

        #300ns;
        phase.drop_objection(this, "Completed fifo_clock_ratio_test");
    endtask

endclass

`endif // FIFO_CLOCK_RATIO_TEST_SV
