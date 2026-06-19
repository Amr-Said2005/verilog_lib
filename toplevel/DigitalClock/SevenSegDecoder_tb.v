// ----------------------------------------------------------------------------
// Testbench:   SevenSegDecoder_tb
// DUT:         SevenSegDecoder
// Description: Exhaustive self-checking testbench for the hex 7-segment decoder.
//              The reference is built independently of the DUT's bit constants:
//              a lit-segment table lists which of segments a..g should light for
//              each hex digit, and the expected active-low pattern is its bitwise
//              complement (lit -> 0). All 16 inputs (0..F) are checked with
//              strict (!==) comparison. Prints only on mismatch; ends with a tally.
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module SevenSegDecoder_tb;

    reg  [3:0] bin;
    wire [6:0] seg;

    SevenSegDecoder dut (.bin(bin), .seg(seg));

    integer errors = 0;
    integer checks = 0;
    integer i;

    // lit[v] = segments that should be ON for value v, bit0=a .. bit6=g.
    // Expected active-low output is ~lit[v]. Derived from the standard hex font,
    // independently of the DUT's encoded constants.
    reg [6:0] lit [0:15];
    initial begin
        lit[0]  = 7'b0111111; // a b c d e f
        lit[1]  = 7'b0000110; // b c
        lit[2]  = 7'b1011011; // a b d e g
        lit[3]  = 7'b1001111; // a b c d g
        lit[4]  = 7'b1100110; // b c f g
        lit[5]  = 7'b1101101; // a c d f g
        lit[6]  = 7'b1111101; // a c d e f g
        lit[7]  = 7'b0000111; // a b c
        lit[8]  = 7'b1111111; // a b c d e f g
        lit[9]  = 7'b1101111; // a b c d f g
        lit[10] = 7'b1110111; // a b c e f g   (A)
        lit[11] = 7'b1111100; // c d e f g     (b)
        lit[12] = 7'b0111001; // a d e f       (C)
        lit[13] = 7'b1011110; // b c d e g     (d)
        lit[14] = 7'b1111001; // a d e f g     (E)
        lit[15] = 7'b1110001; // a e f g       (F)
    end

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            bin = i[3:0];
            #1;
            checks = checks + 1;
            if (seg !== ~lit[i]) begin
                errors = errors + 1;
                $display("  bin=%h seg=%b expected=%b", bin, seg, ~lit[i]);
            end
        end

        if (errors == 0)
            $display("SevenSegDecoder_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("SevenSegDecoder_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
