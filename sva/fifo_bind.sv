//=============================================================================
// File: fifo_bind.sv
// Description: SVA Bind Module for Asynchronous FIFO
//              Cleanly binds verification assertions and coverage to the DUT
//              without modifying synthesizable RTL.
// Standard: IEEE 1800-2017 SystemVerilog
//=============================================================================

`timescale 1ns / 1ps

module fifo_bind;

    bind async_fifo fifo_sva #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_sva_bind (
        // Write Domain Ports
        .wclk         (wclk),
        .wrst_n       (wrst_n),
        .w_inc        (w_inc),
        .wdata        (wdata),
        .wfull        (wfull),
        .almost_full  (almost_full),
        .wptr_gray    (wptr_gray),

        // Read Domain Ports
        .rclk         (rclk),
        .rrst_n       (rrst_n),
        .r_inc        (r_inc),
        .rdata        (rdata),
        .rempty       (rempty),
        .almost_empty (almost_empty),
        .rptr_gray    (rptr_gray)
    );

endmodule
