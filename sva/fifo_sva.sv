//=============================================================================
// File: fifo_sva.sv
// Description: SystemVerilog Assertions (SVA) and Formal Properties for
//              Dual-Clock Asynchronous FIFO.
//              Includes:
//              - Concurrent safety assertions (overflow, underflow, Gray coding)
//              - Pointer increment invariants
//              - Functional coverage properties
// Standard: IEEE 1800-2017 SystemVerilog
//=============================================================================

`timescale 1ns / 1ps

module fifo_sva #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    // Write Domain Ports
    input logic                  wclk,
    input logic                  wrst_n,
    input logic                  w_inc,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic                  wfull,
    input logic                  almost_full,
    input logic [ADDR_WIDTH:0]   wptr_gray,

    // Read Domain Ports
    input logic                  rclk,
    input logic                  rrst_n,
    input logic                  r_inc,
    input logic [DATA_WIDTH-1:0] rdata,
    input logic                  rempty,
    input logic                  almost_empty,
    input logic [ADDR_WIDTH:0]   rptr_gray
);

    // Default clocking / disable for domain properties
    default disable iff (!wrst_n || !rrst_n);

    //-------------------------------------------------------------------------
    // 1. SAFETY ASSERTIONS - Write Clock Domain
    //-------------------------------------------------------------------------

    // Assertion: Gray pointer must change by AT MOST 1 bit on any write clock cycle
    property p_gray_wptr_single_bit_change;
        @(posedge wclk) disable iff (!wrst_n)
        $countones(wptr_gray ^ $past(wptr_gray)) <= 1;
    endproperty
    assert_gray_wptr_step: assert property (p_gray_wptr_single_bit_change)
        else $error("[SVA ERROR] Write Gray pointer changed by more than 1 bit in a single cycle! %b -> %b", $past(wptr_gray), wptr_gray);

    // Assertion: Write pointer must not change when w_inc is 0 or when wfull is asserted
    property p_wptr_stable_when_idle_or_full;
        @(posedge wclk) disable iff (!wrst_n)
        (!w_inc || wfull) |=> (wptr_gray == $past(wptr_gray));
    endproperty
    assert_wptr_stable: assert property (p_wptr_stable_when_idle_or_full)
        else $error("[SVA ERROR] Write pointer changed without valid write increment or when FIFO was full!");

    // Assertion: Write reset state check
    property p_w_reset_state;
        @(posedge wclk)
        !wrst_n |-> (wfull == 1'b0 && wptr_gray == '0);
    endproperty
    assert_w_reset: assert property (p_w_reset_state)
        else $error("[SVA ERROR] Write domain failed to initialize to 0 upon reset!");

    //-------------------------------------------------------------------------
    // 2. SAFETY ASSERTIONS - Read Clock Domain
    //-------------------------------------------------------------------------

    // Assertion: Gray pointer must change by AT MOST 1 bit on any read clock cycle
    property p_gray_rptr_single_bit_change;
        @(posedge rclk) disable iff (!rrst_n)
        $countones(rptr_gray ^ $past(rptr_gray)) <= 1;
    endproperty
    assert_gray_rptr_step: assert property (p_gray_rptr_single_bit_change)
        else $error("[SVA ERROR] Read Gray pointer changed by more than 1 bit in a single cycle! %b -> %b", $past(rptr_gray), rptr_gray);

    // Assertion: Read pointer must not change when r_inc is 0 or when rempty is asserted
    property p_rptr_stable_when_idle_or_empty;
        @(posedge rclk) disable iff (!rrst_n)
        (!r_inc || rempty) |=> (rptr_gray == $past(rptr_gray));
    endproperty
    assert_rptr_stable: assert property (p_rptr_stable_when_idle_or_empty)
        else $error("[SVA ERROR] Read pointer changed without valid read increment or when FIFO was empty!");

    // Assertion: Read reset state check (rempty must be 1 on reset)
    property p_r_reset_state;
        @(posedge rclk)
        !rrst_n |-> (rempty == 1'b1 && rptr_gray == '0);
    endproperty
    assert_r_reset: assert property (p_r_reset_state)
        else $error("[SVA ERROR] Read domain failed to initialize rempty=1 upon reset!");

    //-------------------------------------------------------------------------
    // 3. FUNCTIONAL COVERAGE PROPERTIES (Corner Cases & Activity Tracking)
    //-------------------------------------------------------------------------

    // Cover: FIFO reaches full state
    cover_fifo_full: cover property (
        @(posedge wclk) disable iff (!wrst_n)
        !wfull ##1 wfull
    );

    // Cover: FIFO reaches almost full state
    cover_fifo_almost_full: cover property (
        @(posedge wclk) disable iff (!wrst_n)
        !almost_full ##1 almost_full
    );

    // Cover: FIFO reaches empty state
    cover_fifo_empty: cover property (
        @(posedge rclk) disable iff (!rrst_n)
        !rempty ##1 rempty
    );

    // Cover: FIFO reaches almost empty state
    cover_fifo_almost_empty: cover property (
        @(posedge rclk) disable iff (!rrst_n)
        !almost_empty ##1 almost_empty
    );

    // Cover: Write attempt during full (overflow hazard verification)
    cover_overflow_attempt: cover property (
        @(posedge wclk) disable iff (!wrst_n)
        wfull && w_inc
    );

    // Cover: Read attempt during empty (underflow hazard verification)
    cover_underflow_attempt: cover property (
        @(posedge rclk) disable iff (!rrst_n)
        rempty && r_inc
    );

    // Cover: Consecutive back-to-back writes until full
    cover_consecutive_writes: cover property (
        @(posedge wclk) disable iff (!wrst_n)
        w_inc [* (1 << ADDR_WIDTH)]
    );

    // Cover: Consecutive back-to-back reads until empty
    cover_consecutive_reads: cover property (
        @(posedge rclk) disable iff (!rrst_n)
        r_inc [* (1 << ADDR_WIDTH)]
    );

endmodule
