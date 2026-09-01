//=============================================================================
// File: fifo_read_monitor.sv
// Description: UVM Monitor for FIFO Read Domain (rclk)
//              Monitors read assertions, samples data, and broadcasts to analysis port.
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_READ_MONITOR_SV
`define FIFO_READ_MONITOR_SV

class fifo_read_monitor #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_monitor;

    `uvm_component_param_utils(fifo_read_monitor #(DATA_WIDTH, ADDR_WIDTH))

    virtual fifo_if #(DATA_WIDTH, ADDR_WIDTH) vif;
    uvm_analysis_port #(fifo_item #(DATA_WIDTH)) item_collected_port;

    function new(string name = "fifo_read_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if #(DATA_WIDTH, ADDR_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for ", get_full_name(), ".vif"})
        end
    endfunction

    task run_phase(uvm_phase phase);
        fifo_item #(DATA_WIDTH) item;

        // Wait for reset
        wait (vif.rrst_n === 1'b1);

        forever begin
            @(vif.r_mon_cb);
            if (vif.r_mon_cb.rrst_n && vif.r_mon_cb.r_inc) begin
                item = fifo_item #(DATA_WIDTH)::type_id::create("r_item");
                item.data         = vif.r_mon_cb.rdata;
                item.op_type      = OP_READ;
                item.rempty       = vif.r_mon_cb.rempty;
                item.almost_empty = vif.r_mon_cb.almost_empty;
                item.sim_time     = $realtime;

                `uvm_info("READ_MON", $sformatf("Sampled Read: %s", item.convert2string()), UVM_HIGH)
                item_collected_port.write(item);
            end
        end
    endtask

endclass

`endif // FIFO_READ_MONITOR_SV
