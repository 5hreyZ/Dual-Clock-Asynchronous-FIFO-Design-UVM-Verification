//=============================================================================
// File: fifo_overflow_underflow_seq.sv
// Description: Stress sequence deliberately attempting writes to a full FIFO
//              and reads from an empty FIFO to verify safety bounds and SVA.
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_OVERFLOW_UNDERFLOW_SEQ_SV
`define FIFO_OVERFLOW_UNDERFLOW_SEQ_SV

class fifo_overflow_seq #(parameter int DATA_WIDTH = 8, parameter int DEPTH = 16) extends fifo_base_seq #(DATA_WIDTH);
    `uvm_object_param_utils(fifo_overflow_seq #(DATA_WIDTH, DEPTH))

    function new(string name = "fifo_overflow_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("OVERFLOW_SEQ", $sformatf("Writing %0d items to overflow a %0d-deep FIFO", DEPTH + 5, DEPTH), UVM_LOW)
        for (int i = 0; i < DEPTH + 5; i++) begin
            req = fifo_item #(DATA_WIDTH)::type_id::create("overflow_w_item");
            start_item(req);
            if (!req.randomize() with {
                op_type == OP_WRITE;
                delay   == 0;
            }) begin
                `uvm_fatal("RND_FAIL", "Randomization failed in overflow sequence")
            end
            finish_item(req);
        end
    endtask
endclass

class fifo_underflow_seq #(parameter int DATA_WIDTH = 8) extends fifo_base_seq #(DATA_WIDTH);
    `uvm_object_param_utils(fifo_underflow_seq #(DATA_WIDTH))

    function new(string name = "fifo_underflow_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("UNDERFLOW_SEQ", "Attempting 5 reads from empty FIFO", UVM_LOW)
        for (int i = 0; i < 5; i++) begin
            req = fifo_item #(DATA_WIDTH)::type_id::create("underflow_r_item");
            start_item(req);
            if (!req.randomize() with {
                op_type == OP_READ;
                delay   == 0;
            }) begin
                `uvm_fatal("RND_FAIL", "Randomization failed in underflow sequence")
            end
            finish_item(req);
        end
    endtask
endclass

`endif // FIFO_OVERFLOW_UNDERFLOW_SEQ_SV
