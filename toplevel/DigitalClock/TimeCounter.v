// ----------------------------------------------------------------------------
// Module:      TimeCounter
// Description: 24-hour HH:MM:SS time-of-day counter. On each tick (one rising
//              clock edge per second) and while `start` is high, it advances
//              Seconds 0-59, rolling into Minutes 0-59, rolling into Hours
//              0-23, and wrapping back to 00:00:00 at midnight. Asynchronous,
//              active-high reset clears the time to 00:00:00; holding `start`
//              low freezes the count.
// Parameters:  (none)
// Ports:       clk     - tick clock, one rising edge per second (rising edge)
//              start   - count enable (1 = run, 0 = hold)
//              rst     - asynchronous reset, active high (clears to 00:00:00)
//              Seconds - current seconds, 0-59
//              Minutes - current minutes, 0-59
//              Hours   - current hours,   0-23
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module TimeCounter(
    input  wire clk,
    input  wire start,
    input  wire rst,

    output reg [5:0] Seconds,  // 0-59
    output reg [5:0] Minutes,  // 0-59
    output reg [4:0] Hours     // 0-23
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Seconds <= 6'd0;
            Minutes <= 6'd0;
            Hours   <= 5'd0;
        end
        else if (start) begin
            if (Seconds == 6'd59) begin
                Seconds <= 6'd0;
                if (Minutes == 6'd59) begin
                    Minutes <= 6'd0;
                    if (Hours == 5'd23)
                        Hours <= 5'd0;
                    else
                        Hours <= Hours + 5'd1;
                end
                else begin
                    Minutes <= Minutes + 6'd1;
                end
            end
            else begin
                Seconds <= Seconds + 6'd1;
            end
        end
    end

endmodule
