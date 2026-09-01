//=============================================================================
// File: fifo_burst_seq.sv
// Description: Burst Sequence: writes burst of N items with 0 delay (filling FIFO),
//              followed by burst of N reads with 0 delay (emptying FIFO).
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_BURST_SEQ_SV
`define FIFO_BURST_SEQ_SV

class fifo_burst_write_seq #(parameter int DATA_WIDTH = 8, parameter int DEPTH = 16) extends fifo_base_seq #(DATA_WIDTH);
    `uvm_object_param_utils(fifo_burst_write_seq #(DATA_WIDTH, DEPTH))

    function new(string name = "fifo_burst_write_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("BURST_W_SEQ", $sformatf("Executing zero-delay burst write of %0d elements", DEPTH), UVM_MEDIUM)
        for (int i = 0; i < DEPTH; i++) begin
            req = fifo_item #(DATA_WIDTH)::type_id::create("burst_w_item");
            start_item(req);
            if (!req.randomize() with {
                op_type == OP_WRITE;
                delay   == 0;
            }) begin
                `uvm_fatal("RND_FAIL", "Randomization failed in burst write seq")
            end
            finish_item(req);
        end
    endtask
endclass

class fifo_burst_read_seq #(parameter int DATA_WIDTH = 8, parameter int DEPTH = 16) extends fifo_base_seq #(DATA_WIDTH);
    `uvm_object_param_utils(fifo_burst_read_seq #(DATA_WIDTH, DEPTH))

    function new(string name = "fifo_burst_read_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("BURST_R_SEQ", $sformatf("Executing zero-delay burst read of %0d elements", DEPTH), UVM_MEDIUM)
        for (int i = 0; i < DEPTH; i++) begin
            req = fifo_item #(DATA_WIDTH)::type_id::create("burst_r_item");
            start_item(req);
            if (!req.randomize() with {
                op_type == OP_READ;
                delay   == 0;
            }) begin
                `uvm_fatal("RND_FAIL", "Randomization failed in burst read seq")
            end
            finish_item(req);
        end
    endtask
endclass

`endif // FIFO_BURST_SEQ_SV
