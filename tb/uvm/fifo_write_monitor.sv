//=============================================================================
// File: fifo_write_monitor.sv
// Description: UVM Monitor for FIFO Write Domain (wclk)
//              Monitors write assertions, samples data, and broadcasts to analysis port.
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_WRITE_MONITOR_SV
`define FIFO_WRITE_MONITOR_SV

class fifo_write_monitor #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_monitor;

    `uvm_component_param_utils(fifo_write_monitor #(DATA_WIDTH, ADDR_WIDTH))

    virtual fifo_if #(DATA_WIDTH, ADDR_WIDTH) vif;
    uvm_analysis_port #(fifo_item #(DATA_WIDTH)) item_collected_port;

    function new(string name = "fifo_write_monitor", uvm_component parent = null);
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
        wait (vif.wrst_n === 1'b1);

        forever begin
            @(vif.w_mon_cb);
            if (vif.w_mon_cb.wrst_n && vif.w_mon_cb.w_inc) begin
                item = fifo_item #(DATA_WIDTH)::type_id::create("w_item");
                item.data         = vif.w_mon_cb.wdata;
                item.op_type      = OP_WRITE;
                item.wfull        = vif.w_mon_cb.wfull;
                item.almost_full  = vif.w_mon_cb.almost_full;
                item.sim_time     = $realtime;

                `uvm_info("WRITE_MON", $sformatf("Sampled Write: %s", item.convert2string()), UVM_HIGH)
                item_collected_port.write(item);
            end
        end
    endtask

endclass

`endif // FIFO_WRITE_MONITOR_SV
