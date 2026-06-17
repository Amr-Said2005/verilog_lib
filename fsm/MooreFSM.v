// ----------------------------------------------------------------------------
// Module:      MooreFSM
// Description: Moore finite state machine implementing an overlapping "101"
//              sequence detector. The output depends only on the current state
//              (not on the input), so it is registered and glitch-free by
//              construction. `out` is high for the one cycle the machine spends
//              in the MATCH state — the cycle after the third bit of "101" has
//              been clocked in. Overlapping is supported: the trailing "1" of
//              one match doubles as the leading "1" of the next.
// Parameters:  (none)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (returns to IDLE)
//              in    - single-bit serial input, one bit per clock
//              out   - single-bit Moore output (1 while in the MATCH state)
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module MooreFSM(
    input      clk,
    input      reset,
    input      in,
    output reg out
);

    // States named by the longest suffix of the input seen so far that is also
    // a prefix of the target pattern "101".
    localparam [1:0]
        S_IDLE = 2'b00,   // suffix ""    — nothing useful seen
        S_1    = 2'b01,   // suffix "1"
        S_10   = 2'b10,   // suffix "10"
        S_101  = 2'b11;   // suffix "101" — full match

    reg [1:0] state, next_state;

    // State register (sequential, asynchronous reset)
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // Next-state logic (combinational)
    always @(*) begin
        case (state)
            S_IDLE: next_state = in ? S_1   : S_IDLE;
            S_1:    next_state = in ? S_1   : S_10;
            S_10:   next_state = in ? S_101 : S_IDLE;
            S_101:  next_state = in ? S_1   : S_10;   // overlap on trailing "1"
            default: next_state = S_IDLE;
        endcase
    end

    // Output logic (Moore: a pure function of the current state)
    always @(*) begin
        out = (state == S_101);
    end

endmodule
