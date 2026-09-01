//=============================================================================
// File: fifo_write_seq.sv
// Description: UVM Sequence to generate configurable write transactions
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_WRITE_SEQ_SV
`define FIFO_WRITE_SEQ_SV

class fifo_write_seq #(parameter int DATA_WIDTH = 8) extends fifo_base_seq #(DATA_WIDTH);

    `uvm_object_param_utils(fifo_write_seq #(DATA_WIDTH))

    rand int unsigned   num_transactions;
    rand data_pattern_e pattern;
    rand int unsigned   fixed_delay;
    rand bit            use_fixed_delay;

    constraint c_num_tx {
        num_transactions inside {[10:50]};
    }

    constraint c_delay_mode {
        use_fixed_delay == 1'b0;
        fixed_delay == 0;
    }

    function new(string name = "fifo_write_seq");
        super.new(name);
        pattern = PAT_RANDOM;
    endfunction

    virtual task body();
        `uvm_info("WRITE_SEQ", $sformatf("Starting write sequence with %0d transactions (Pattern=%s)",
                  num_transactions, pattern.name()), UVM_MEDIUM)

        for (int i = 0; i < num_transactions; i++) begin
            req = fifo_item #(DATA_WIDTH)::type_id::create("w_item");
            start_item(req);
            if (!req.randomize() with {
                op_type == OP_WRITE;
                pattern_type == local::pattern;
                if (local::use_fixed_delay) delay == local::fixed_delay;
            }) begin
                `uvm_fatal("RND_FAIL", "Randomization failed in fifo_write_seq")
            end
            finish_item(req);
        end

        `uvm_info("WRITE_SEQ", "Completed write sequence", UVM_MEDIUM)
    endtask

endclass

`endif // FIFO_WRITE_SEQ_SV
