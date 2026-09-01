//=============================================================================
// File: fifo_if.sv
// Description: SystemVerilog Dual Clock-Domain Interface for Asynchronous FIFO
//              Encapsulates write domain and read domain signals with dedicated
//              clocking blocks for cycle-accurate, race-free UVM driving/sampling.
// Standard: IEEE 1800-2017 SystemVerilog
//=============================================================================

`timescale 1ns / 1ps

interface fifo_if #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input logic wclk,
    input logic rclk
);

    // Write Clock Domain Signals
    logic                  wrst_n;
    logic                  w_inc;
    logic [DATA_WIDTH-1:0] wdata;
    logic                  wfull;
    logic                  almost_full;

    // Read Clock Domain Signals
    logic                  rrst_n;
    logic                  r_inc;
    logic [DATA_WIDTH-1:0] rdata;
    logic                  rempty;
    logic                  almost_empty;

    //-------------------------------------------------------------------------
    // Write Domain Clocking Blocks
    //-------------------------------------------------------------------------
    clocking w_driver_cb @(posedge wclk);
        default input #1ns output #1ns;
        output w_inc;
        output wdata;
        input  wfull;
        input  almost_full;
    endclocking

    clocking w_mon_cb @(posedge wclk);
        default input #1ns output #1ns;
        input w_inc;
        input wdata;
        input wfull;
        input almost_full;
        input wrst_n;
    endclocking

    //-------------------------------------------------------------------------
    // Read Domain Clocking Blocks
    //-------------------------------------------------------------------------
    clocking r_driver_cb @(posedge rclk);
        default input #1ns output #1ns;
        output r_inc;
        input  rdata;
        input  rempty;
        input  almost_empty;
    endclocking

    clocking r_mon_cb @(posedge rclk);
        default input #1ns output #1ns;
        input r_inc;
        input rdata;
        input rempty;
        input almost_empty;
        input rrst_n;
    endclocking

    //-------------------------------------------------------------------------
    // Modports
    //-------------------------------------------------------------------------
    modport w_driver_mp (clocking w_driver_cb, output wrst_n);
    modport w_mon_mp    (clocking w_mon_cb);
    modport r_driver_mp (clocking r_driver_cb, output rrst_n);
    modport r_mon_mp    (clocking r_mon_cb);

    modport dut_mp (
        input  wclk, wrst_n, w_inc, wdata,
        output wfull, almost_full,
        input  rclk, rrst_n, r_inc,
        output rdata, rempty, almost_empty
    );

endinterface
