//=============================================================================
// File: fifo_write_agent.sv
// Description: UVM Agent for Write Clock Domain
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_WRITE_AGENT_SV
`define FIFO_WRITE_AGENT_SV

class fifo_write_agent #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_agent;

    `uvm_component_param_utils(fifo_write_agent #(DATA_WIDTH, ADDR_WIDTH))

    fifo_write_driver    #(DATA_WIDTH, ADDR_WIDTH) driver;
    fifo_write_sequencer #(DATA_WIDTH)             sequencer;
    fifo_write_monitor   #(DATA_WIDTH, ADDR_WIDTH) monitor;

    uvm_analysis_port #(fifo_item #(DATA_WIDTH))   ap;

    function new(string name = "fifo_write_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = fifo_write_monitor #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = fifo_write_driver    #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("driver", this);
            sequencer = fifo_write_sequencer #(DATA_WIDTH)::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = monitor.item_collected_port;
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass

`endif // FIFO_WRITE_AGENT_SV
