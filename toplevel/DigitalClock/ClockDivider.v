// ----------------------------------------------------------------------------
// Module:      ClockDivider
// Description: Parameterized integer clock divider. Toggles clk_out once every
//              DIVISOR input clock cycles, producing a 50%-duty-cycle square
//              wave at clk_in / (2 * DIVISOR). Used to derive a slow tick (such
//              as a per-second strobe) from a fast board oscillator.
// Parameters:  DIVISOR - input cycles per output half-period (default 2)
// Ports:       clk_in  - input clock (rising edge)
//              rst     - asynchronous reset, active high
//              clk_out - divided clock output (50% duty cycle)
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module ClockDivider #(parameter DIVISOR = 2)
(
    input  wire clk_in,
    input  wire rst,        // active-high
    output reg  clk_out
);
    reg [$clog2(DIVISOR)-1:0] cnt;

    // Toggle clk_out every DIVISOR input cycles -> 50% duty cycle.
    // Output frequency = clk_in / (2 * DIVISOR). Toggling (not a 1-cycle pulse)
    // gives a real square wave that drives a visibly-blinking LED when DIVISOR
    // is large enough.
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            cnt     <= 0;
            clk_out <= 1'b0;
        end else if (cnt == DIVISOR - 1) begin
            cnt     <= 0;
            clk_out <= ~clk_out;
        end else begin
            cnt     <= cnt + 1'b1;
        end
    end
endmodule
