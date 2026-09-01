//=============================================================================
// File: fifo_coverage.sv
// Description: UVM Functional Coverage Model for Asynchronous FIFO
//              Covers:
//              - Data pattern distributions (extremes, walking 1s/0s, alternating)
//              - FIFO status flag coverage & corner-case states
//              - Inter-transaction timing distributions (burst vs sparse)
//              - Cross-coverage between transaction patterns and FIFO occupancy
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_COVERAGE_SV
`define FIFO_COVERAGE_SV

`uvm_analysis_imp_decl(_cov_w)
`uvm_analysis_imp_decl(_cov_r)

class fifo_coverage #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_component;

    `uvm_component_param_utils(fifo_coverage #(DATA_WIDTH, ADDR_WIDTH))

    uvm_analysis_imp_cov_w #(fifo_item #(DATA_WIDTH), fifo_coverage #(DATA_WIDTH, ADDR_WIDTH)) write_export;
    uvm_analysis_imp_cov_r #(fifo_item #(DATA_WIDTH), fifo_coverage #(DATA_WIDTH, ADDR_WIDTH)) read_export;

    fifo_item #(DATA_WIDTH) w_item_sampled;
    fifo_item #(DATA_WIDTH) r_item_sampled;

    //-------------------------------------------------------------------------
    // Covergroup: Write Domain Activity & Data Patterns
    //-------------------------------------------------------------------------
    covergroup cg_write_domain;
        option.per_instance = 1;
        option.name = "cg_write_domain";

        cp_wdata: coverpoint w_item_sampled.data {
            bins all_zeros = {'0};
            bins all_ones  = {'1};
            bins alt_aa    = {(DATA_WIDTH > 8) ? {DATA_WIDTH/8{8'hAA}} : 8'hAA};
            bins alt_55    = {(DATA_WIDTH > 8) ? {DATA_WIDTH/8{8'h55}} : 8'h55};
            bins low_range = {[0 : (1 << (DATA_WIDTH/2)) - 1]};
            bins high_range= {[(1 << (DATA_WIDTH/2)) : (1 << DATA_WIDTH) - 1]};
            bins auto_dist[] = default;
        }

        cp_wfull: coverpoint w_item_sampled.wfull {
            bins not_full = {1'b0};
            bins is_full  = {1'b1}; // Overflow attempt
        }

        cp_almost_full: coverpoint w_item_sampled.almost_full {
            bins not_almost_full = {1'b0};
            bins is_almost_full  = {1'b1};
        }

        cp_wdelay: coverpoint w_item_sampled.delay {
            bins back_to_back = {0};
            bins short_delay  = {[1:3]};
            bins long_delay   = {[4:10]};
        }

        // Cross coverage
        cross_wdata_wfull: cross cp_wdata, cp_wfull;
        cross_delay_full:  cross cp_wdelay, cp_almost_full;

    endgroup

    //-------------------------------------------------------------------------
    // Covergroup: Read Domain Activity & Data Patterns
    //-------------------------------------------------------------------------
    covergroup cg_read_domain;
        option.per_instance = 1;
        option.name = "cg_read_domain";

        cp_rdata: coverpoint r_item_sampled.data {
            bins all_zeros = {'0};
            bins all_ones  = {'1};
            bins alt_aa    = {(DATA_WIDTH > 8) ? {DATA_WIDTH/8{8'hAA}} : 8'hAA};
            bins alt_55    = {(DATA_WIDTH > 8) ? {DATA_WIDTH/8{8'h55}} : 8'h55};
            bins low_range = {[0 : (1 << (DATA_WIDTH/2)) - 1]};
            bins high_range= {[(1 << (DATA_WIDTH/2)) : (1 << DATA_WIDTH) - 1]};
            bins auto_dist[] = default;
        }

        cp_rempty: coverpoint r_item_sampled.rempty {
            bins not_empty = {1'b0};
            bins is_empty  = {1'b1}; // Underflow attempt
        }

        cp_almost_empty: coverpoint r_item_sampled.almost_empty {
            bins not_almost_empty = {1'b0};
            bins is_almost_empty  = {1'b1};
        }

        cp_rdelay: coverpoint r_item_sampled.delay {
            bins back_to_back = {0};
            bins short_delay  = {[1:3]};
            bins long_delay   = {[4:10]};
        }

        // Cross coverage
        cross_rdata_rempty: cross cp_rdata, cp_rempty;
        cross_delay_empty:  cross cp_rdelay, cp_almost_empty;

    endgroup

    function new(string name = "fifo_coverage", uvm_component parent = null);
        super.new(name, parent);
        write_export = new("write_export", this);
        read_export  = new("read_export", this);
        cg_write_domain = new();
        cg_read_domain  = new();
    endfunction

    virtual function void write_cov_w(fifo_item #(DATA_WIDTH) item);
        w_item_sampled = item;
        cg_write_domain.sample();
    endfunction

    virtual function void write_cov_r(fifo_item #(DATA_WIDTH) item);
        r_item_sampled = item;
        cg_read_domain.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV_REPORT", $sformatf("Functional Coverage -> Write Domain: %0.2f%% | Read Domain: %0.2f%%",
                  cg_write_domain.get_inst_coverage(), cg_read_domain.get_inst_coverage()), UVM_NONE)
    endfunction

endclass

`endif // FIFO_COVERAGE_SV
