`timescale 1ns / 1ps

//=============================================================================
// File: fifo_pkg.sv
// Description: UVM Verification Package for Asynchronous FIFO
//              Packages all sequence items, drivers, monitors, agents,
//              scoreboard, coverage model, sequences, and tests.
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_PKG_SV
`define FIFO_PKG_SV

`include "uvm_macros.svh"

package fifo_pkg;

    import uvm_pkg::*;

    // Core transaction items
    `include "fifo_item.sv"

    // Drivers & Sequencers
    `include "fifo_write_sequencer.sv"
    `include "fifo_read_sequencer.sv"
    `include "fifo_write_driver.sv"
    `include "fifo_read_driver.sv"

    // Monitors
    `include "fifo_write_monitor.sv"
    `include "fifo_read_monitor.sv"

    // Agents
    `include "fifo_write_agent.sv"
    `include "fifo_read_agent.sv"

    // Scoreboard & Coverage Model
    `include "fifo_scoreboard.sv"
    `include "fifo_coverage.sv"

    // Top Environment
    `include "fifo_env.sv"

    // Sequences
    `include "seq/fifo_base_seq.sv"
    `include "seq/fifo_write_seq.sv"
    `include "seq/fifo_read_seq.sv"
    `include "seq/fifo_burst_seq.sv"
    `include "seq/fifo_overflow_underflow_seq.sv"

    // Test Suite
    `include "tests/fifo_base_test.sv"
    `include "tests/fifo_sanity_test.sv"
    `include "tests/fifo_burst_test.sv"
    `include "tests/fifo_concurrent_test.sv"
    `include "tests/fifo_overflow_underflow_test.sv"
    `include "tests/fifo_clock_ratio_test.sv"
    `include "tests/fifo_random_stress_test.sv"

    // Non-parameterized wrappers for UVM factory lookup by name
    `include "tests/fifo_test_wrappers.sv"

endpackage : fifo_pkg

`endif // FIFO_PKG_SV
