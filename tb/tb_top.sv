//=============================================================================
// File: tb_top.sv
// Description: Top-Level Simulation Testbench for Asynchronous FIFO
//              - Generates independent asynchronous write and read clocks
//              - Provides asynchronous reset sequencing
//              - Instantiates DUT, SVA Bind, and Virtual Interface
//              - Registers interface in uvm_config_db and executes run_test()
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`timescale 1ns / 1ps

`include "uvm_macros.svh"
import uvm_pkg::*;
import fifo_pkg::*;

module tb_top;

    // Parameters
    localparam int DATA_WIDTH          = 8;
    localparam int ADDR_WIDTH          = 4; // Depth = 16
    localparam int SYNC_STAGES         = 2;
    localparam int ALMOST_FULL_THRESH  = 2;
    localparam int ALMOST_EMPTY_THRESH = 2;

    // Clock periods in nanoseconds (can be overridden via plusarg)
    real wclk_half_period = 5.0;  // 100 MHz (10ns period)
    real rclk_half_period = 12.5; // 40 MHz (25ns period)

    // Clock signals
    logic wclk;
    logic rclk;

    // Clock Generation
    initial begin
        wclk = 0;
        forever #(wclk_half_period) wclk = ~wclk;
    end

    initial begin
        rclk = 0;
        forever #(rclk_half_period) rclk = ~rclk;
    end

    // Interface Instantiation
    fifo_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut_if (
        .wclk(wclk),
        .rclk(rclk)
    );

    // DUT Instantiation
    async_fifo #(
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH),
        .SYNC_STAGES         (SYNC_STAGES),
        .ALMOST_FULL_THRESH  (ALMOST_FULL_THRESH),
        .ALMOST_EMPTY_THRESH (ALMOST_EMPTY_THRESH)
    ) u_dut (
        // Write Domain
        .wclk         (dut_if.wclk),
        .wrst_n       (dut_if.wrst_n),
        .w_inc        (dut_if.w_inc),
        .wdata        (dut_if.wdata),
        .wfull        (dut_if.wfull),
        .almost_full  (dut_if.almost_full),

        // Read Domain
        .rclk         (dut_if.rclk),
        .rrst_n       (dut_if.rrst_n),
        .r_inc        (dut_if.r_inc),
        .rdata        (dut_if.rdata),
        .rempty       (dut_if.rempty),
        .almost_empty (dut_if.almost_empty)
    );

    // SVA Bind Instantiation
    fifo_bind u_fifo_bind();

    // Reset Sequencing & UVM Run
    initial begin
        // Reset initialization
        dut_if.wrst_n = 1'b0;
        dut_if.rrst_n = 1'b0;
        dut_if.w_inc  = 1'b0;
        dut_if.wdata  = '0;
        dut_if.r_inc  = 1'b0;

        // Parse runtime clock overrides from command line if provided
        void'($value$plusargs("WCLK_HP=%f", wclk_half_period));
        void'($value$plusargs("RCLK_HP=%f", rclk_half_period));

        // Waveform dumping for debugging
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);

        // Deassert resets asynchronously with slight offset to test independence
        #30ns;
        dut_if.wrst_n = 1'b1;
        #20ns;
        dut_if.rrst_n = 1'b1;

        `uvm_info("TB_TOP", $sformatf("Resets released. wclk_period=%0.2fns, rclk_period=%0.2fns",
                  wclk_half_period * 2, rclk_half_period * 2), UVM_LOW)
    end

    initial begin
        string test_name;
        // Register virtual interface in config_db
        uvm_config_db#(virtual fifo_if #(DATA_WIDTH, ADDR_WIDTH))::set(null, "*", "vif", dut_if);

        // Parse test name plusarg or default to random stress test
        if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) begin
            test_name = "fifo_random_stress_test_wrapper";
        end

        // Execute UVM Testbench
        run_test(test_name);
    end

    // Safety watchdog timeout to prevent infinite simulation
    initial begin
        #10000ns;
        `uvm_info("WATCHDOG", "Simulation complete / watchdog boundary reached.", UVM_LOW)
        $finish();
    end

endmodule
