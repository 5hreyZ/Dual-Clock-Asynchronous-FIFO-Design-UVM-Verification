//=============================================================================
// File: async_fifo.sv
// Description: Top-Level Parameterized Dual-Clock Asynchronous FIFO
//              Features:
//              - Parameterized DATA_WIDTH and DEPTH (2^ADDR_WIDTH)
//              - Gray-coded pointer domain crossing
//              - Parameterized 2-FF/N-FF Synchronizers with CDC synthesis attributes
//              - Full, Empty, Almost-Full, and Almost-Empty flags
//              - Robust against metastability and race conditions
// Standard: IEEE 1800-2017 SystemVerilog
//=============================================================================

`timescale 1ns / 1ps

module async_fifo #(
    parameter int DATA_WIDTH          = 8,
    parameter int ADDR_WIDTH          = 4,
    parameter int SYNC_STAGES         = 2,
    parameter int ALMOST_FULL_THRESH  = 2,
    parameter int ALMOST_EMPTY_THRESH = 2
) (
    // Write Clock Domain
    input  logic                  wclk,
    input  logic                  wrst_n,
    input  logic                  w_inc,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic                  wfull,
    output logic                  almost_full,

    // Read Clock Domain
    input  logic                  rclk,
    input  logic                  rrst_n,
    input  logic                  r_inc,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  rempty,
    output logic                  almost_empty
);

    localparam int PTR_WIDTH = ADDR_WIDTH + 1;

    // Internal interconnect signals
    logic [ADDR_WIDTH-1:0] waddr;
    logic [ADDR_WIDTH-1:0] raddr;
    logic [PTR_WIDTH-1:0]  wptr_gray;
    logic [PTR_WIDTH-1:0]  rptr_gray;
    logic [PTR_WIDTH-1:0]  wptr_gray_sync;
    logic [PTR_WIDTH-1:0]  rptr_gray_sync;

    // Write Enable Qualifier: Only write when requested and not full
    logic w_en;
    assign w_en = w_inc & ~wfull;

    //-------------------------------------------------------------------------
    // 1. Dual-Port Memory Core
    //-------------------------------------------------------------------------
    fifo_mem #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_mem (
        .wclk  (wclk),
        .w_en  (w_en),
        .waddr (waddr),
        .wdata (wdata),
        .raddr (raddr),
        .rdata (rdata)
    );

    //-------------------------------------------------------------------------
    // 2. Synchronizer: Read Pointer -> Write Clock Domain
    //-------------------------------------------------------------------------
    sync_2ff #(
        .WIDTH  (PTR_WIDTH),
        .STAGES (SYNC_STAGES)
    ) u_sync_r2w (
        .clk   (wclk),
        .rst_n (wrst_n),
        .din   (rptr_gray),
        .dout  (rptr_gray_sync)
    );

    //-------------------------------------------------------------------------
    // 3. Synchronizer: Write Pointer -> Read Clock Domain
    //-------------------------------------------------------------------------
    sync_2ff #(
        .WIDTH  (PTR_WIDTH),
        .STAGES (SYNC_STAGES)
    ) u_sync_w2r (
        .clk   (rclk),
        .rst_n (rrst_n),
        .din   (wptr_gray),
        .dout  (wptr_gray_sync)
    );

    //-------------------------------------------------------------------------
    // 4. Write Pointer & Full Status Handler (Write Domain)
    //-------------------------------------------------------------------------
    wptr_full #(
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ALMOST_FULL_THRESH (ALMOST_FULL_THRESH)
    ) u_wptr_full (
        .wclk           (wclk),
        .wrst_n         (wrst_n),
        .w_inc          (w_inc),
        .rptr_gray_sync (rptr_gray_sync),
        .wfull          (wfull),
        .almost_full    (almost_full),
        .waddr          (waddr),
        .wptr_gray      (wptr_gray)
    );

    //-------------------------------------------------------------------------
    // 5. Read Pointer & Empty Status Handler (Read Domain)
    //-------------------------------------------------------------------------
    rptr_empty #(
        .ADDR_WIDTH          (ADDR_WIDTH),
        .ALMOST_EMPTY_THRESH (ALMOST_EMPTY_THRESH)
    ) u_rptr_empty (
        .rclk           (rclk),
        .rrst_n         (rrst_n),
        .r_inc          (r_inc),
        .wptr_gray_sync (wptr_gray_sync),
        .rempty         (rempty),
        .almost_empty   (almost_empty),
        .raddr          (raddr),
        .rptr_gray      (rptr_gray)
    );

endmodule
