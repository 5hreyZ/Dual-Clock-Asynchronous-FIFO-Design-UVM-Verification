`timescale 1ns / 1ps

//=============================================================================
// File: fifo_read_sequencer.sv
// Description: UVM Sequencer for Read Clock Domain
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_READ_SEQUENCER_SV
`define FIFO_READ_SEQUENCER_SV

class fifo_read_sequencer #(parameter int DATA_WIDTH = 8) extends uvm_sequencer #(fifo_item #(DATA_WIDTH));
    `uvm_component_param_utils(fifo_read_sequencer #(DATA_WIDTH))

    function new(string name = "fifo_read_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif // FIFO_READ_SEQUENCER_SV
