// ----------------------------------------------------------------------------
// Module:      DigitalClockTop
// Description: Top-level digital clock for the DE10-Standard board. Wires the
//              system together: a ClockDivider derives a per-second tick from
//              the board's fast oscillator, a TimeCounter keeps HH:MM:SS, a
//              ClockDisplay drives the six 7-segment HEX displays, and a
//              MachineFSM derives a machine operating mode from the hour. The
//              DIV parameter sets the divider ratio (50,000,000 gives a ~0.5 Hz
//              square wave -> one tick every ~2 s from a 50 MHz clock); override
//              it with a small value in simulation for fast ticks.
// Parameters:  DIV - ClockDivider ratio (default 50,000,000 for a 50 MHz board)
// Ports:       start - count enable for the clock
//              clk   - board clock, 50 MHz (rising edge)
//              rst   - asynchronous reset, active high
//              HEX0..HEX5 - the six 7-segment displays (HH:MM:SS, active-low)
//              state - machine operating mode from MachineFSM (2-bit)
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module DigitalClockTop #(
    parameter DIV = 50000000
)(
    input  wire start,
    input  wire clk,
    input  wire rst,

    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [1:0] state
);

    wire       clk_out;
    wire [5:0] Seconds;
    wire [5:0] Minutes;
    wire [4:0] Hours;

    MachineFSM control_unit (
        .Hours(Hours),
        .clk(clk),
        .rst(rst),
        .state(state)
    );

    ClockDivider #(DIV) clk_div (
        .clk_in(clk),
        .clk_out(clk_out),
        .rst(rst)
    );

    TimeCounter clock (
        .clk(clk_out),
        .Seconds(Seconds),
        .Minutes(Minutes),
        .Hours(Hours),
        .start(start),
        .rst(rst)
    );

    ClockDisplay display (
        .Seconds(Seconds),
        .Minutes(Minutes),
        .Hours(Hours),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5)
    );

endmodule
