//=============================================================================
// File: wptr_full.sv
// Description: Write Pointer Handler & Full/Almost-Full Status Generation
//              Converts binary write pointer to Gray code and detects full 
//              condition against synchronized read pointer.
// Standard: IEEE 1800-2017 SystemVerilog
//=============================================================================

`timescale 1ns / 1ps

module wptr_full #(
    parameter int ADDR_WIDTH          = 4,
    parameter int ALMOST_FULL_THRESH  = 2  // Assert almost_full when (DEPTH - occupancy) <= THRESH
) (
    input  logic                  wclk,
    input  logic                  wrst_n,
    input  logic                  w_inc,
    input  logic [ADDR_WIDTH:0]   rptr_gray_sync,  // Synchronized Gray read pointer
    output logic                  wfull,
    output logic                  almost_full,
    output logic [ADDR_WIDTH-1:0] waddr,
    output logic [ADDR_WIDTH:0]   wptr_gray
);

    localparam int DEPTH = (1 << ADDR_WIDTH);

    logic [ADDR_WIDTH:0] wptr_bin;
    logic [ADDR_WIDTH:0] wptr_bin_next;
    logic [ADDR_WIDTH:0] wptr_gray_next;
    logic                wfull_val;
    logic                almost_full_val;

    // Increment binary pointer on valid write when not full
    assign wptr_bin_next = wptr_bin + (w_inc & ~wfull);

    // Binary to Gray conversion: G = (B >> 1) ^ B
    assign wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;

    // Memory write address comes from lower ADDR_WIDTH bits of binary pointer
    assign waddr = wptr_bin[ADDR_WIDTH-1:0];

    // FIFO Full Condition in Gray Code:
    // Full when MSB and MSB-1 are inverted, and remaining bits are identical.
    // e.g. wptr = 1000, rptr = 0100 (both address 0, but write has wrapped around)
    assign wfull_val = (wptr_gray_next == {~rptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1], 
                                           rptr_gray_sync[ADDR_WIDTH-2:0]});

    // Gray-to-Binary converter for synchronized read pointer to compute occupancy
    logic [ADDR_WIDTH:0] rptr_bin_sync;
    always_comb begin
        rptr_bin_sync[ADDR_WIDTH] = rptr_gray_sync[ADDR_WIDTH];
        for (int i = ADDR_WIDTH - 1; i >= 0; i--) begin
            rptr_bin_sync[i] = rptr_bin_sync[i+1] ^ rptr_gray_sync[i];
        end
    end

    // Compute write domain occupancy
    logic [ADDR_WIDTH:0] w_occupancy;
    assign w_occupancy = wptr_bin_next - rptr_bin_sync;
    assign almost_full_val = (w_occupancy >= (DEPTH - ALMOST_FULL_THRESH));

    // Register write pointer and status flags
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin    <= '0;
            wptr_gray   <= '0;
            wfull       <= 1'b0;
            almost_full <= 1'b0;
        end else begin
            wptr_bin    <= wptr_bin_next;
            wptr_gray   <= wptr_gray_next;
            wfull       <= wfull_val;
            almost_full <= almost_full_val;
        end
    end

endmodule
