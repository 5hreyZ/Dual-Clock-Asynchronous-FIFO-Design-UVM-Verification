//=============================================================================
// File: fifo_overflow_underflow_test.sv
// Description: Corner-case test verifying overflow and underflow protection
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_OVERFLOW_UNDERFLOW_TEST_SV
`define FIFO_OVERFLOW_UNDERFLOW_TEST_SV

class fifo_overflow_underflow_test #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends fifo_base_test #(DATA_WIDTH, ADDR_WIDTH);

    localparam int DEPTH = (1 << ADDR_WIDTH);
    `uvm_component_param_utils(fifo_overflow_underflow_test #(DATA_WIDTH, ADDR_WIDTH))

    function new(string name = "fifo_overflow_underflow_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_underflow_seq #(DATA_WIDTH)         u_seq;
        fifo_overflow_seq  #(DATA_WIDTH, DEPTH)  o_seq;
        fifo_burst_read_seq #(DATA_WIDTH, DEPTH) br_seq;

        phase.raise_objection(this, "Starting fifo_overflow_underflow_test");

        u_seq  = fifo_underflow_seq #(DATA_WIDTH)::type_id::create("u_seq");
        o_seq  = fifo_overflow_seq  #(DATA_WIDTH, DEPTH)::type_id::create("o_seq");
        br_seq = fifo_burst_read_seq #(DATA_WIDTH, DEPTH)::type_id::create("br_seq");

        `uvm_info("TEST", "Step 1: Deliberately reading from EMPTY FIFO (Underflow check)", UVM_LOW)
        u_seq.start(env.read_agent.sequencer);

        #50ns;

        `uvm_info("TEST", "Step 2: Writing past DEPTH (Overflow check)", UVM_LOW)
        o_seq.start(env.write_agent.sequencer);

        #100ns;

        `uvm_info("TEST", "Step 3: Reading all valid data", UVM_LOW)
        br_seq.start(env.read_agent.sequencer);

        #50ns;

        `uvm_info("TEST", "Step 4: Reading from EMPTY FIFO again (Underflow check 2)", UVM_LOW)
        u_seq.start(env.read_agent.sequencer);

        #100ns;
        phase.drop_objection(this, "Completed fifo_overflow_underflow_test");
    endtask

endclass

`endif // FIFO_OVERFLOW_UNDERFLOW_TEST_SV
