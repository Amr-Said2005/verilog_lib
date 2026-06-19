// ----------------------------------------------------------------------------
// Testbench:   ClockDisplay_tb
// DUT:         ClockDisplay  (instantiates SevenSegDecoder)
// Description: Self-checking testbench for the HH:MM:SS display formatter. The
//              reference independently splits each field into tens/ones digits
//              and decodes them via a lit-segment table (the active-low pattern
//              is the bitwise complement of the lit segments), then checks all
//              six HEX outputs with strict (!==) comparison. Because the three
//              fields drive independent decoder pairs, each is swept over its
//              full range (Seconds/Minutes 0-59, Hours 0-23); a block of random
//              combined times adds cross-checks. Prints only on mismatch.
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module ClockDisplay_tb;

    reg  [5:0] Seconds, Minutes;
    reg  [4:0] Hours;
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    ClockDisplay dut (.Seconds(Seconds), .Minutes(Minutes), .Hours(Hours),
                      .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
                      .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5));

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

    function [6:0] decode;
        input [3:0] v;
        begin
            decode = ~lit[v];
        end
    endfunction

    task check;
        begin
            checks = checks + 6;
            if (HEX0 !== decode(Seconds % 10)) begin errors=errors+1; $display("  HEX0 sec=%0d got=%b",Seconds,HEX0); end
            if (HEX1 !== decode(Seconds / 10)) begin errors=errors+1; $display("  HEX1 sec=%0d got=%b",Seconds,HEX1); end
            if (HEX2 !== decode(Minutes % 10)) begin errors=errors+1; $display("  HEX2 min=%0d got=%b",Minutes,HEX2); end
            if (HEX3 !== decode(Minutes / 10)) begin errors=errors+1; $display("  HEX3 min=%0d got=%b",Minutes,HEX3); end
            if (HEX4 !== decode(Hours   % 10)) begin errors=errors+1; $display("  HEX4 hr=%0d got=%b",Hours,HEX4); end
            if (HEX5 !== decode(Hours   / 10)) begin errors=errors+1; $display("  HEX5 hr=%0d got=%b",Hours,HEX5); end
        end
    endtask

    initial begin
        Seconds = 0; Minutes = 0; Hours = 0; #1; check;

        // Full sweep of each field (others held).
        Minutes = 6'd34; Hours = 5'd12;
        for (i = 0; i < 60; i = i + 1) begin Seconds = i[5:0]; #1; check; end
        Seconds = 6'd21; Hours = 5'd9;
        for (i = 0; i < 60; i = i + 1) begin Minutes = i[5:0]; #1; check; end
        Seconds = 6'd45; Minutes = 6'd7;
        for (i = 0; i < 24; i = i + 1) begin Hours = i[4:0]; #1; check; end

        // Random combined times.
        for (i = 0; i < 300; i = i + 1) begin
            Seconds = ({$random} % 60);
            Minutes = ({$random} % 60);
            Hours   = ({$random} % 24);
            #1; check;
        end

        if (errors == 0)
            $display("ClockDisplay_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("ClockDisplay_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
