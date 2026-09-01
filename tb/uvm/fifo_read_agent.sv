//=============================================================================
// File: fifo_read_agent.sv
// Description: UVM Agent for Read Clock Domain
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_READ_AGENT_SV
`define FIFO_READ_AGENT_SV

class fifo_read_agent #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_agent;

    `uvm_component_param_utils(fifo_read_agent #(DATA_WIDTH, ADDR_WIDTH))

    fifo_read_driver    #(DATA_WIDTH, ADDR_WIDTH) driver;
    fifo_read_sequencer #(DATA_WIDTH)             sequencer;
    fifo_read_monitor   #(DATA_WIDTH, ADDR_WIDTH) monitor;

    uvm_analysis_port #(fifo_item #(DATA_WIDTH))  ap;

    function new(string name = "fifo_read_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = fifo_read_monitor #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = fifo_read_driver    #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("driver", this);
            sequencer = fifo_read_sequencer #(DATA_WIDTH)::type_id::create("sequencer", this);
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

`endif // FIFO_READ_AGENT_SV
