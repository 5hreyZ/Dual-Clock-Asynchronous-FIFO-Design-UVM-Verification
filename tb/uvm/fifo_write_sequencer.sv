//=============================================================================
// File: fifo_write_sequencer.sv
// Description: UVM Sequencer for Write Clock Domain
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_WRITE_SEQUENCER_SV
`define FIFO_WRITE_SEQUENCER_SV

class fifo_write_sequencer #(parameter int DATA_WIDTH = 8) extends uvm_sequencer #(fifo_item #(DATA_WIDTH));
    `uvm_component_param_utils(fifo_write_sequencer #(DATA_WIDTH))

    function new(string name = "fifo_write_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif // FIFO_WRITE_SEQUENCER_SV
