// ----------------------------------------------------------------------------
// Module:      SequenceDetector
// Description: Parameterized overlapping sequence detector. Watches a serial
//              input stream for a specific bit pattern and asserts `detected`
//              for one clock cycle on each match. Uses a Moore FSM internally.
//              Default pattern: 4'b1011 (overlapping — the tail of one match
//              can serve as the head of the next).
// Parameters:  PATTERN - bit pattern to detect (default 4'b1011)
//              LEN     - pattern length in bits (default 4)
// Ports:       clk      - input clock (rising edge)
//              reset    - asynchronous reset, active high
//              din      - serial input data, one bit per clock
//              detected - pulses high for one cycle on pattern match
// Author:      Amr Said
// Date:        2026-06-10
// ----------------------------------------------------------------------------
module SequenceDetector #(
    parameter [3:0] PATTERN = 4'b1011,
    parameter       LEN     = 4
)(
    input  clk,
    input  reset,
    input  din,
    output detected
);

   endmodule
