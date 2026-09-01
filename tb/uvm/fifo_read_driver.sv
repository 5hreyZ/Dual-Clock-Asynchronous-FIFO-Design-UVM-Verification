//=============================================================================
// File: fifo_read_driver.sv
// Description: UVM Driver for FIFO Read Clock Domain (rclk)
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_READ_DRIVER_SV
`define FIFO_READ_DRIVER_SV

class fifo_read_driver #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_driver #(fifo_item #(DATA_WIDTH));

    `uvm_component_param_utils(fifo_read_driver #(DATA_WIDTH, ADDR_WIDTH))

    virtual fifo_if #(DATA_WIDTH, ADDR_WIDTH) vif;

    function new(string name = "fifo_read_driver", uvm_component parent = null);
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
        vif.r_driver_cb.r_inc <= 1'b0;

        // Wait for reset release
        wait (vif.rrst_n === 1'b1);
        @(vif.r_driver_cb);

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_item(fifo_item #(DATA_WIDTH) item);
        // Apply inter-transaction delay
        repeat (item.delay) begin
            vif.r_driver_cb.r_inc <= 1'b0;
            @(vif.r_driver_cb);
        end

        if (item.op_type == OP_READ) begin
            vif.r_driver_cb.r_inc <= 1'b1;
            @(vif.r_driver_cb);
            vif.r_driver_cb.r_inc <= 1'b0;
        end else begin
            vif.r_driver_cb.r_inc <= 1'b0;
            @(vif.r_driver_cb);
        end
    endtask

endclass

`endif // FIFO_READ_DRIVER_SV
