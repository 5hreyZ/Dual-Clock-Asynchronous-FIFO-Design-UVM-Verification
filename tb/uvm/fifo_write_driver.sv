`timescale 1ns / 1ps

//=============================================================================
// File: fifo_write_driver.sv
// Description: UVM Driver for FIFO Write Clock Domain (wclk)
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_WRITE_DRIVER_SV
`define FIFO_WRITE_DRIVER_SV

class fifo_write_driver #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_driver #(fifo_item #(DATA_WIDTH));

    `uvm_component_param_utils(fifo_write_driver #(DATA_WIDTH, ADDR_WIDTH))

    virtual fifo_if #(DATA_WIDTH, ADDR_WIDTH) vif;

    function new(string name = "fifo_write_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if #(DATA_WIDTH, ADDR_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for ", get_full_name(), ".vif"})
        end
    endfunction

    task run_phase(uvm_phase phase);
        // Reset signals
        vif.w_driver_cb.w_inc <= 1'b0;
        vif.w_driver_cb.wdata <= '0;

        // Wait for reset release
        wait (vif.wrst_n === 1'b1);
        @(vif.w_driver_cb);

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_item(fifo_item #(DATA_WIDTH) item);
        // Apply inter-transaction delay
        repeat (item.delay) begin
            vif.w_driver_cb.w_inc <= 1'b0;
            vif.w_driver_cb.wdata <= '0;
            @(vif.w_driver_cb);
        end

        if (item.op_type == OP_WRITE) begin
            vif.w_driver_cb.w_inc <= 1'b1;
            vif.w_driver_cb.wdata <= item.data;
            @(vif.w_driver_cb);
            vif.w_driver_cb.w_inc <= 1'b0;
            vif.w_driver_cb.wdata <= '0;
        end else begin
            vif.w_driver_cb.w_inc <= 1'b0;
            @(vif.w_driver_cb);
        end
    endtask

endclass

`endif // FIFO_WRITE_DRIVER_SV
