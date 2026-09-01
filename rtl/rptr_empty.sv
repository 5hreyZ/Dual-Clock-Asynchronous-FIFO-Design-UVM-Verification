//=============================================================================
// File: rptr_empty.sv
// Description: Read Pointer Handler & Empty/Almost-Empty Status Generation
//              Converts binary read pointer to Gray code and detects empty
//              condition against synchronized write pointer.
// Standard: IEEE 1800-2017 SystemVerilog
//=============================================================================

`timescale 1ns / 1ps

module rptr_empty #(
    parameter int ADDR_WIDTH          = 4,
    parameter int ALMOST_EMPTY_THRESH = 2  // Assert almost_empty when occupancy <= THRESH
) (
    input  logic                  rclk,
    input  logic                  rrst_n,
    input  logic                  r_inc,
    input  logic [ADDR_WIDTH:0]   wptr_gray_sync,  // Synchronized Gray write pointer
    output logic                  rempty,
    output logic                  almost_empty,
    output logic [ADDR_WIDTH-1:0] raddr,
    output logic [ADDR_WIDTH:0]   rptr_gray
);

    logic [ADDR_WIDTH:0] rptr_bin;
    logic [ADDR_WIDTH:0] rptr_bin_next;
    logic [ADDR_WIDTH:0] rptr_gray_next;
    logic                rempty_val;
    logic                almost_empty_val;

    // Increment binary pointer on valid read when not empty
    assign rptr_bin_next = rptr_bin + (r_inc & ~rempty);

    // Binary to Gray conversion: G = (B >> 1) ^ B
    assign rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;

    // Memory read address comes from lower ADDR_WIDTH bits of binary pointer
    assign raddr = rptr_bin[ADDR_WIDTH-1:0];

    // FIFO Empty Condition in Gray Code:
    // Empty when read pointer equals write pointer exactly
    assign rempty_val = (rptr_gray_next == wptr_gray_sync);

    // Gray-to-Binary converter for synchronized write pointer to compute occupancy
    logic [ADDR_WIDTH:0] wptr_bin_sync;
    always_comb begin
        wptr_bin_sync[ADDR_WIDTH] = wptr_gray_sync[ADDR_WIDTH];
        for (int i = ADDR_WIDTH - 1; i >= 0; i--) begin
            wptr_bin_sync[i] = wptr_bin_sync[i+1] ^ wptr_gray_sync[i];
        end
    end

    // Compute read domain occupancy
    logic [ADDR_WIDTH:0] r_occupancy;
    assign r_occupancy = wptr_bin_sync - rptr_bin_next;
    assign almost_empty_val = (r_occupancy <= ALMOST_EMPTY_THRESH);

    // Register read pointer and status flags
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin     <= '0;
            rptr_gray    <= '0;
            rempty       <= 1'b1;  // Resets to empty state
            almost_empty <= 1'b1;
        end else begin
            rptr_bin     <= rptr_bin_next;
            rptr_gray    <= rptr_gray_next;
            rempty       <= rempty_val;
            almost_empty <= almost_empty_val;
        end
    end

endmodule
