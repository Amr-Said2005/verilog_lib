// ----------------------------------------------------------------------------
// Module:      SequenceDetector
// Description: Parameterized overlapping sequence detector. Watches a serial
//              input stream for a specific bit pattern and asserts `detected`
//              for one clock cycle on each match. Implemented as a length-LEN
//              shift register compared against PATTERN — a Moore-style detector
//              whose output is a pure function of the stored bit history, so
//              overlapping matches (the tail of one match serving as the head
//              of the next) are handled naturally. The match appears the cycle
//              after the final pattern bit is clocked in.
//              Default pattern: 4'b1011.
// Parameters:  LEN     - pattern length in bits (default 4)
//              PATTERN - bit pattern to detect, LEN bits wide (default 4'b1011)
// Ports:       clk      - input clock (rising edge)
//              reset    - asynchronous reset, active high (clears the window)
//              din      - serial input data, one bit per clock (MSB-first)
//              detected - pulses high for one cycle on each pattern match
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module SequenceDetector #(
    parameter            LEN     = 4,
    parameter [LEN-1:0]  PATTERN = 4'b1011
)(
    input  clk,
    input  reset,
    input  din,
    output detected
);

    // Sliding window of the LEN most recent input bits. din enters at the LSB
    // and shifts left, so window[LEN-1] is the oldest bit and window[0] the
    // newest — matching the natural MSB-first reading of PATTERN.
    reg [LEN-1:0] window;

    always @(posedge clk or posedge reset) begin
        if (reset)
            window <= {LEN{1'b0}};
        else
            window <= {window[LEN-2:0], din};
    end

    assign detected = (window == PATTERN);

endmodule
