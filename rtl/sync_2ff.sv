//=============================================================================
// File: sync_2ff.sv
// Description: Parameterized Multi-Stage Synchronizer with CDC Attributes
//              Used to synchronize multi-bit Gray-coded pointers across 
//              independent, asynchronous clock domains.
// Standard: IEEE 1800-2017 SystemVerilog
//=============================================================================

`timescale 1ns / 1ps

module sync_2ff #(
    parameter int WIDTH  = 4,  // Bit width of the synchronized bus (e.g. ADDR_WIDTH + 1)
    parameter int STAGES = 2   // Number of synchronizer flip-flop stages (>= 2)
) (
    input  logic             clk,      // Destination clock domain
    input  logic             rst_n,    // Destination domain active-low asynchronous reset
    input  logic [WIDTH-1:0] din,      // Asynchronous data input from source domain
    output logic [WIDTH-1:0] dout      // Synchronized data output in destination domain
);

    // Ensure at least 2 stages are used for metastability resolution
    initial begin
        if (STAGES < 2) begin
            $fatal(1, "[CDC ERROR] %m: Synchronizer STAGES must be at least 2 (configured with %0d)", STAGES);
        end
    end

    // Multi-stage shift register for synchronization
    // Attributes to prevent logic optimization and enforce co-location in silicon
    (* ASYNC_REG = "TRUE" *)
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    (* dont_touch = "true" *)
    logic [WIDTH-1:0] sync_regs [STAGES-1:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < STAGES; i++) begin
                sync_regs[i] <= '0;
            end
        end else begin
            sync_regs[0] <= din;
            for (int i = 1; i < STAGES; i++) begin
                sync_regs[i] <= sync_regs[i-1];
            end
        end
    end

    assign dout = sync_regs[STAGES-1];

endmodule
