//=============================================================================
// File: fifo_scoreboard.sv
// Description: UVM Scoreboard with Golden Queue Reference Model
//              Verifies:
//              - In-order data integrity across asynchronous clock domains
//              - Proper drop/ignore of overflow write transactions
//              - Proper flag response on underflow read transactions
//              - Latency analysis and comprehensive end-of-test verification report
// Standard: IEEE 1800-2017 SystemVerilog / UVM 1.2
//=============================================================================

`ifndef FIFO_SCOREBOARD_SV
`define FIFO_SCOREBOARD_SV

`uvm_analysis_imp_decl(_write)
`uvm_analysis_imp_decl(_read)

class fifo_scoreboard #(parameter int DATA_WIDTH = 8, parameter int ADDR_WIDTH = 4) extends uvm_scoreboard;

    `uvm_component_param_utils(fifo_scoreboard #(DATA_WIDTH, ADDR_WIDTH))

    // Analysis exports from agents
    uvm_analysis_imp_write #(fifo_item #(DATA_WIDTH), fifo_scoreboard #(DATA_WIDTH, ADDR_WIDTH)) write_export;
    uvm_analysis_imp_read  #(fifo_item #(DATA_WIDTH), fifo_scoreboard #(DATA_WIDTH, ADDR_WIDTH)) read_export;

    // Golden reference queue
    protected fifo_item #(DATA_WIDTH) expected_queue[$];

    // Verification statistics counters
    int unsigned num_valid_writes      = 0;
    int unsigned num_overflow_writes   = 0;
    int unsigned num_valid_reads       = 0;
    int unsigned num_underflow_reads   = 0;
    int unsigned num_matches           = 0;
    int unsigned num_mismatches        = 0;

    realtime min_latency = 1000000.0;
    realtime max_latency = 0.0;
    realtime total_latency = 0.0;
    real avg_lat;

    function new(string name = "fifo_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        write_export = new("write_export", this);
        read_export  = new("read_export", this);
    endfunction

    // Write domain transaction processor
    virtual function void write_write(fifo_item #(DATA_WIDTH) item);
        if (item.wfull) begin
            num_overflow_writes++;
            `uvm_info("SCB_OVERFLOW", $sformatf("Write attempt while FULL ignored by DUT: %s", item.convert2string()), UVM_MEDIUM)
        end else begin
            fifo_item #(DATA_WIDTH) clone_item;
            $cast(clone_item, item.clone());
            expected_queue.push_back(clone_item);
            num_valid_writes++;
            `uvm_info("SCB_WRITE", $sformatf("Pushed to reference queue [depth=%0d]: %s", expected_queue.size(), item.convert2string()), UVM_HIGH)
        end
    endfunction

    // Read domain transaction processor
    virtual function void write_read(fifo_item #(DATA_WIDTH) item);
        fifo_item #(DATA_WIDTH) exp_item;
        realtime latency;

        if (item.rempty) begin
            num_underflow_reads++;
            `uvm_info("SCB_UNDERFLOW", $sformatf("Read attempt while EMPTY handled: %s", item.convert2string()), UVM_MEDIUM)
        end else begin
            num_valid_reads++;
            if (expected_queue.size() == 0) begin
                num_mismatches++;
                `uvm_error("SCB_EMPTY_POP", $sformatf("DUT produced read data 0x%0h but reference queue was EMPTY!", item.data))
            end else begin
                exp_item = expected_queue.pop_front();
                latency = item.sim_time - exp_item.sim_time;

                if (latency < min_latency) min_latency = latency;
                if (latency > max_latency) max_latency = latency;
                total_latency += latency;

                if (item.data === exp_item.data) begin
                    num_matches++;
                    `uvm_info("SCB_MATCH", $sformatf("MATCH: Data=0x%0h | Latency=%0.2fns | Remaining In Flight=%0d",
                              item.data, latency, expected_queue.size()), UVM_HIGH)
                end else begin
                    num_mismatches++;
                    `uvm_error("SCB_MISMATCH", $sformatf("MISMATCH! Expected: 0x%0h, Actual: 0x%0h | %s",
                               exp_item.data, item.data, item.convert2string()))
                end
            end
        end
    endfunction

    // End of test integrity checks & report
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (expected_queue.size() != 0) begin
            `uvm_warning("SCB_DRAIN_WARNING", $sformatf("%0d transactions remained unread in reference queue at end of test!", expected_queue.size()))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        avg_lat = (num_matches > 0) ? (total_latency / num_matches) : 0.0;

        `uvm_info("SCB_REPORT", $sformatf("\n=========================================================================================\n                             ASYNC FIFO SCOREBOARD SUMMARY REPORT                        \n=========================================================================================\n Total Valid Writes Pushed   : %0d\n Total Valid Reads Checked   : %0d\n Overflow Write Attempts     : %0d\n Underflow Read Attempts     : %0d\n Successful Data Matches     : %0d\n Data Mismatches / Errors    : %0d\n Items Remaining In-Flight   : %0d\n-----------------------------------------------------------------------------------------\n Cross-Clock Min Latency     : %0.2f ns\n Cross-Clock Max Latency     : %0.2f ns\n Cross-Clock Avg Latency     : %0.2f ns\n=========================================================================================\n%s\n=========================================================================================",
            num_valid_writes,
            num_valid_reads,
            num_overflow_writes,
            num_underflow_reads,
            num_matches,
            num_mismatches,
            expected_queue.size(),
            (num_matches > 0) ? min_latency : 0.0,
            max_latency,
            avg_lat,
            ((num_mismatches == 0 && (num_valid_writes == num_valid_reads)) ?
               "                       >>> TEST STATUS: ALL CHECKS PASSED <<<                    " :
               "                       >>> TEST STATUS: FAILED CHECKS DETECTED <<<               ")),
            UVM_NONE)
    endfunction

endclass

`endif // FIFO_SCOREBOARD_SV
