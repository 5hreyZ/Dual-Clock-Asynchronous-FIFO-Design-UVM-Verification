//=============================================================================
// File: fifo_mem.sv
// Description: Dual-Port Memory Array for Asynchronous FIFO
//              Synchronous write on wclk, asynchronous/combinational read on rclk.
// Standard: IEEE 1800-2017 SystemVerilog
//=============================================================================

`timescale 1ns / 1ps

module fifo_mem #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4,
    parameter int DEPTH      = (1 << ADDR_WIDTH)
) (
    input  logic                  wclk,
    input  logic                  w_en,
    input  logic [ADDR_WIDTH-1:0] waddr,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [ADDR_WIDTH-1:0] raddr,
    output logic [DATA_WIDTH-1:0] rdata
);

    // Memory array
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Synchronous write
    always_ff @(posedge wclk) begin
        if (w_en) begin
            mem[waddr] <= wdata;
        end
    end

    // Asynchronous read (continuous assignment for zero read latency)
    assign rdata = mem[raddr];

endmodule
