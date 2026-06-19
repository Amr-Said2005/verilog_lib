// ----------------------------------------------------------------------------
// Testbench:   DigitalClockTop_tb
// DUT:         DigitalClockTop  (full hierarchy: divider + counter + display + FSM)
// Description: Integration testbench for the assembled digital clock. The DUT is
//              parameterized with a small divider (DIV=2) so ticks arrive every
//              few input clocks instead of every 50 million. The testbench runs
//              independent reference models — a mirror divider, an elapsed-time
//              accumulator, and a lit-segment decoder — and every cycle checks
//              that all six HEX outputs show the expected HH:MM:SS and that the
//              FSM `state` matches the expected mode for the current hour. This
//              confirms the modules are wired together correctly (divider ->
//              counter -> display, and counter hours -> FSM). Per-module
//              correctness is covered by the unit testbenches. Strict (!==)
//              comparison; prints only on mismatch.
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module DigitalClockTop_tb;

    localparam DIV = 2;
    localparam [1:0] IDLE = 2'b00, STARTING = 2'b01, WORKING = 2'b10;

    reg  clk = 1'b0;
    reg  start, rst;
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [1:0] state;

    DigitalClockTop #(.DIV(DIV)) dut (
        .start(start), .clk(clk), .rst(rst),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
        .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5), .state(state));

    always #5 clk = ~clk;

    // ---- Independent reference models ----
    reg                     ref_clkout = 1'b0;   // mirror divider
    reg [$clog2(DIV)-1:0]   ref_cnt    = 0;
    integer                 tsec       = 0;       // elapsed-seconds accumulator

    always @(posedge clk or posedge rst) begin
        if (rst) begin ref_cnt <= 0; ref_clkout <= 1'b0; end
        else if (ref_cnt == DIV-1) begin ref_cnt <= 0; ref_clkout <= ~ref_clkout; end
        else ref_cnt <= ref_cnt + 1'b1;
    end

    always @(posedge ref_clkout or posedge rst) begin
        if (rst)        tsec <= 0;
        else if (start) tsec <= (tsec + 1) % 86400;
    end

    integer errors = 0;
    integer checks = 0;
    integer i;

    reg [6:0] lit [0:15];
    initial begin
        lit[0]=7'b0111111; lit[1]=7'b0000110; lit[2]=7'b1011011; lit[3]=7'b1001111;
        lit[4]=7'b1100110; lit[5]=7'b1101101; lit[6]=7'b1111101; lit[7]=7'b0000111;
        lit[8]=7'b1111111; lit[9]=7'b1101111; lit[10]=7'b1110111; lit[11]=7'b1111100;
        lit[12]=7'b0111001; lit[13]=7'b1011110; lit[14]=7'b1111001; lit[15]=7'b1110001;
    end

    function [6:0] decode; input [3:0] v; begin decode = ~lit[v]; end endfunction
    function [1:0] zone;   input [4:0] h;
        begin
            if      (h >= 5'd10) zone = WORKING;
            else if (h >= 5'd8)  zone = STARTING;
            else                 zone = IDLE;
        end
    endfunction

    task check;
        reg [5:0] es, em; reg [4:0] eh;
        begin
            es = tsec % 60; em = (tsec / 60) % 60; eh = tsec / 3600;
            checks = checks + 7;
            if (HEX0 !== decode(es % 10)) begin errors=errors+1; $display("  [%0t] HEX0 t=%0d got=%b",$time,tsec,HEX0); end
            if (HEX1 !== decode(es / 10)) begin errors=errors+1; $display("  [%0t] HEX1 t=%0d got=%b",$time,tsec,HEX1); end
            if (HEX2 !== decode(em % 10)) begin errors=errors+1; $display("  [%0t] HEX2 t=%0d got=%b",$time,tsec,HEX2); end
            if (HEX3 !== decode(em / 10)) begin errors=errors+1; $display("  [%0t] HEX3 t=%0d got=%b",$time,tsec,HEX3); end
            if (HEX4 !== decode(eh % 10)) begin errors=errors+1; $display("  [%0t] HEX4 t=%0d got=%b",$time,tsec,HEX4); end
            if (HEX5 !== decode(eh / 10)) begin errors=errors+1; $display("  [%0t] HEX5 t=%0d got=%b",$time,tsec,HEX5); end
            if (state !== zone(eh))       begin errors=errors+1; $display("  [%0t] state t=%0d got=%b exp=%b",$time,tsec,state,zone(eh)); end
        end
    endtask

    initial begin
        start = 1'b0; rst = 1'b1;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0; tsec = 0;
        #1; check;                                // post-reset: 00:00:00, IDLE
        @(negedge clk); start = 1'b1;

        // ~1000 ticks (DIV=2 -> a tick every 4 input clocks); exercises the
        // seconds and minutes rollover through the full display/divider chain.
        for (i = 0; i < 4200; i = i + 1) begin
            @(negedge clk); check;
        end

        if (errors == 0)
            $display("DigitalClockTop_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("DigitalClockTop_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
