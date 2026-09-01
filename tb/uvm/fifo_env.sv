//=============================================================================
// File: fifo_env.sv
// Description: UVM Verification Environment assembling Write Agent, Read Agent,
//              Scoreboard, and Functional Coverage Collector.
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_ENV_SV
`define FIFO_ENV_SV

class fifo_env #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_env;

    `uvm_component_param_utils(fifo_env #(DATA_WIDTH, ADDR_WIDTH))

    fifo_write_agent    #(DATA_WIDTH, ADDR_WIDTH) write_agent;
    fifo_read_agent     #(DATA_WIDTH, ADDR_WIDTH) read_agent;
    fifo_scoreboard     #(DATA_WIDTH, ADDR_WIDTH) scoreboard;
    fifo_coverage       #(DATA_WIDTH, ADDR_WIDTH) coverage;

    function new(string name = "fifo_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        write_agent = fifo_write_agent #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("write_agent", this);
        read_agent  = fifo_read_agent  #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("read_agent", this);
        scoreboard  = fifo_scoreboard  #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("scoreboard", this);
        coverage    = fifo_coverage    #(DATA_WIDTH, ADDR_WIDTH)::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect Write Agent Analysis Port to Scoreboard and Coverage
        write_agent.ap.connect(scoreboard.write_export);
        write_agent.ap.connect(coverage.write_export);

        // Connect Read Agent Analysis Port to Scoreboard and Coverage
        read_agent.ap.connect(scoreboard.read_export);
        read_agent.ap.connect(coverage.read_export);
    endfunction

endclass

`endif // FIFO_ENV_SV
