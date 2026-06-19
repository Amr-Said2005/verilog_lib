// ----------------------------------------------------------------------------
// Module:      ClockDisplay
// Description: Drives the six DE10-Standard 7-segment (HEX) displays with the
//              digital-clock value in HH:MM:SS format:
//
//                  HEX5 HEX4   HEX3 HEX2   HEX1 HEX0
//                  [ Hours ]   [Minutes]   [Seconds]
//
//              Each binary field is split into tens/ones BCD digits and fed
//              through a SevenSegDecoder. The DE10-Standard HEX displays are
//              common-anode (active-low); SevenSegDecoder already emits active-
//              low patterns with seg[0]=a..seg[6]=g, so the outputs connect
//              directly to the HEX pins.
// Parameters:  (none)
// Ports:       Seconds - seconds value, 0-59
//              Minutes - minutes value, 0-59
//              Hours   - hours value,   0-23
//              HEX0    - seconds ones digit (7-seg, active-low)
//              HEX1    - seconds tens digit
//              HEX2    - minutes ones digit
//              HEX3    - minutes tens digit
//              HEX4    - hours   ones digit
//              HEX5    - hours   tens digit
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module ClockDisplay (
    input  wire [5:0] Seconds,  // 0-59
    input  wire [5:0] Minutes,  // 0-59
    input  wire [4:0] Hours,    // 0-23

    output wire [6:0] HEX0,     // Seconds ones
    output wire [6:0] HEX1,     // Seconds tens
    output wire [6:0] HEX2,     // Minutes ones
    output wire [6:0] HEX3,     // Minutes tens
    output wire [6:0] HEX4,     // Hours   ones
    output wire [6:0] HEX5      // Hours   tens
);

    // Split each binary value into tens and ones BCD digits.
    wire [3:0] sec_ones = Seconds % 6'd10;
    wire [3:0] sec_tens = Seconds / 6'd10;

    wire [3:0] min_ones = Minutes % 6'd10;
    wire [3:0] min_tens = Minutes / 6'd10;

    wire [3:0] hr_ones  = Hours   % 5'd10;
    wire [3:0] hr_tens  = Hours   / 5'd10;

    // Seconds
    SevenSegDecoder dec_sec_ones (.bin(sec_ones), .seg(HEX0));
    SevenSegDecoder dec_sec_tens (.bin(sec_tens), .seg(HEX1));

    // Minutes
    SevenSegDecoder dec_min_ones (.bin(min_ones), .seg(HEX2));
    SevenSegDecoder dec_min_tens (.bin(min_tens), .seg(HEX3));

    // Hours
    SevenSegDecoder dec_hr_ones  (.bin(hr_ones),  .seg(HEX4));
    SevenSegDecoder dec_hr_tens  (.bin(hr_tens),  .seg(HEX5));

endmodule
