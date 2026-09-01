//=============================================================================
// File: fifo_read_seq.sv
// Description: UVM Sequence to generate configurable read transactions
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_READ_SEQ_SV
`define FIFO_READ_SEQ_SV

class fifo_read_seq #(parameter int DATA_WIDTH = 8) extends fifo_base_seq #(DATA_WIDTH);

    `uvm_object_param_utils(fifo_read_seq #(DATA_WIDTH))

    rand int unsigned num_transactions;
    rand int unsigned fixed_delay;
    rand bit          use_fixed_delay;

    constraint c_num_tx {
        num_transactions inside {[10:50]};
    }

    constraint c_delay_mode {
        use_fixed_delay == 1'b0;
        fixed_delay == 0;
    }

    function new(string name = "fifo_read_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("READ_SEQ", $sformatf("Starting read sequence with %0d transactions", num_transactions), UVM_MEDIUM)

        for (int i = 0; i < num_transactions; i++) begin
            req = fifo_item #(DATA_WIDTH)::type_id::create("r_item");
            start_item(req);
            if (!req.randomize() with {
                op_type == OP_READ;
                if (local::use_fixed_delay) delay == local::fixed_delay;
            }) begin
                `uvm_fatal("RND_FAIL", "Randomization failed in fifo_read_seq")
            end
            finish_item(req);
        end

        `uvm_info("READ_SEQ", "Completed read sequence", UVM_MEDIUM)
    endtask

endclass

`endif // FIFO_READ_SEQ_SV
