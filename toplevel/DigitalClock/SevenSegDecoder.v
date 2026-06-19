// ----------------------------------------------------------------------------
// Module:      SevenSegDecoder
// Description: Hexadecimal (0-F) to seven-segment decoder for common-anode
//              displays (segments are active-low: 0 = lit). Bit order matches
//              the DE10-Standard HEX pin mapping: seg[0]=a, seg[1]=b, seg[2]=c,
//              seg[3]=d, seg[4]=e, seg[5]=f, seg[6]=g.
// Parameters:  (none)
// Ports:       bin - 4-bit hexadecimal input (0..F)
//              seg - 7-bit active-low segment pattern {g,f,e,d,c,b,a}
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module SevenSegDecoder (
    input  wire [3:0] bin,   // 4-bit hexadecimal input (0 to F)
    output reg  [6:0] seg    // 7-bit output for active-low segments
);

    always @(*) begin
        case (bin)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hb: seg = 7'b0000011; // b
            4'hC: seg = 7'b1000110; // C
            4'hd: seg = 7'b0100001; // d
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // all segments off
        endcase
    end

endmodule
