`timescale 1ns / 1ps

//=============================================================================
// File: fifo_base_seq.sv
// Description: Base UVM Sequence for FIFO verification
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_BASE_SEQ_SV
`define FIFO_BASE_SEQ_SV

class fifo_base_seq #(parameter int DATA_WIDTH = 8) extends uvm_sequence #(fifo_item #(DATA_WIDTH));
    `uvm_object_param_utils(fifo_base_seq #(DATA_WIDTH))

    function new(string name = "fifo_base_seq");
        super.new(name);
    endfunction
endclass

`endif // FIFO_BASE_SEQ_SV
