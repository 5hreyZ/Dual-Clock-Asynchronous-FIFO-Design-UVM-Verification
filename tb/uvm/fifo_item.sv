//=============================================================================
// File: fifo_item.sv
// Description: UVM Sequence Item representing FIFO transactions (Write / Read)
//              Features randomized payload, timing delays, pattern constraints,
//              and metadata for scoreboard tracking.
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_ITEM_SV
`define FIFO_ITEM_SV

typedef enum bit [1:0] {
    OP_WRITE = 2'b00,
    OP_READ  = 2'b01,
    OP_IDLE  = 2'b10
} fifo_op_e;

typedef enum bit [2:0] {
    PAT_RANDOM     = 3'b000,
    PAT_ALL_ZEROS  = 3'b001,
    PAT_ALL_ONES   = 3'b010,
    PAT_ALT_BITS   = 3'b011, // 0xAA / 0x55
    PAT_WALKING_1S = 3'b100,
    PAT_WALKING_0S = 3'b101
} data_pattern_e;

class fifo_item #(parameter int DATA_WIDTH = 8) extends uvm_sequence_item;

    // Transaction Payload & Operation
    rand bit [DATA_WIDTH-1:0] data;
    rand fifo_op_e            op_type;
    rand int unsigned         delay;
    rand data_pattern_e       pattern_type;

    // Status sampled during transaction
    bit                       wfull;
    bit                       rempty;
    bit                       almost_full;
    bit                       almost_empty;
    realtime                  sim_time;

    // Constraints
    constraint c_delay_distribution {
        delay dist {
            0       := 70, // 70% back-to-back transactions
            [1:3]   := 20, // 20% short delay
            [4:10]  := 10  // 10% long delay
        };
    }

    constraint c_pattern_default {
        soft pattern_type == PAT_RANDOM;
    }

    `uvm_object_param_utils_begin(fifo_item #(DATA_WIDTH))
        `uvm_field_int(data,         UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(fifo_op_e,   op_type, UVM_ALL_ON)
        `uvm_field_int(delay,        UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(wfull,        UVM_ALL_ON)
        `uvm_field_int(rempty,       UVM_ALL_ON)
        `uvm_field_int(almost_full,  UVM_ALL_ON)
        `uvm_field_int(almost_empty, UVM_ALL_ON)
        `uvm_field_real(sim_time,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "fifo_item");
        super.new(name);
    endfunction

    // Post-randomize hook to apply selected data patterns
    function void post_randomize();
        case (pattern_type)
            PAT_ALL_ZEROS:  data = '0;
            PAT_ALL_ONES:   data = '1;
            PAT_ALT_BITS:   data = (DATA_WIDTH > 8) ? {DATA_WIDTH/8{8'hAA}} : 8'hAA;
            PAT_WALKING_1S: data = (1 << ($urandom_range(0, DATA_WIDTH-1)));
            PAT_WALKING_0S: data = ~(1 << ($urandom_range(0, DATA_WIDTH-1)));
            default:        /* keep randomized data */;
        endcase
    endfunction

    virtual function string convert2string();
        return $sformatf("op=%s data=0x%0h delay=%0d full=%b empty=%b a_full=%b a_empty=%b @%0t",
                        op_type.name(), data, delay, wfull, rempty, almost_full, almost_empty, sim_time);
    endfunction

endclass

`endif // FIFO_ITEM_SV
