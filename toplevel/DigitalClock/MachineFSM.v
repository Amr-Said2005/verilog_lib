// ----------------------------------------------------------------------------
// Module:      MachineFSM
// Description: Moore FSM that selects a machine operating mode from the time of
//              day (the Hours field of the digital clock):
//                  IDLE     Hours  0..7    (00:00-07:59)  machine off
//                  STARTING Hours  8..9    (08:00-09:59)  warming up
//                  WORKING  Hours 10..23   (10:00-23:59)  running
//              and back to IDLE when Hours wraps to 0 at midnight. Each state
//              re-decodes all three hour zones, so the mode is correct even
//              after a reset at an arbitrary time of day.
// Parameters:  (none)
// Ports:       clk   - input clock (rising edge)
//              rst   - asynchronous reset, active high (returns to IDLE)
//              Hours - current hour from the clock, 0..23
//              state - current operating mode (00 IDLE, 01 STARTING, 10 WORKING)
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module MachineFSM (
    input  wire       clk,
    input  wire       rst,        // active-high
    input  wire [4:0] Hours,      // 0..23
    output reg  [1:0] state       // current operating mode
);

    // State encoding
    localparam [1:0] IDLE     = 2'b00,
                     STARTING = 2'b01,
                     WORKING  = 2'b10;

    reg [1:0] next_state;

    // ---- Next-state logic (combinational) ----
    always @(*) begin
        case (state)
            IDLE: begin
                if      (Hours >= 5'd10)               next_state = WORKING;
                else if (Hours >= 5'd8)                next_state = STARTING;
                else                                   next_state = IDLE;
            end

            STARTING: begin
                if      (Hours >= 5'd10)               next_state = WORKING;
                else if (Hours < 5'd8)                 next_state = IDLE;     // midnight wrap / reset
                else                                   next_state = STARTING;
            end

            WORKING: begin
                if      (Hours < 5'd8)                 next_state = IDLE;     // wrapped to 0..7
                else if (Hours < 5'd10)                next_state = STARTING; // reset into 8..9
                else                                   next_state = WORKING;
            end

            default: next_state = IDLE;
        endcase
    end

    // ---- State register (sequential) ----
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

endmodule
