// ----------------------------------------------------------------------------
// Testbench:   SequenceDetector_tb
// DUT:         SequenceDetector  (two parameterizations)
// Description: Self-checking testbench for the parameterized overlapping
//              sequence detector. Two DUT instances are driven from the same
//              serial stream — a 4-bit "1011" detector and a 3-bit "101"
//              detector — to exercise the PATTERN/LEN parameters. The reference
//              model is structurally independent of the DUT's shift register: it
//              records the full input history in an array and recomputes each
//              expected detection by directly comparing the trailing LEN samples
//              against PATTERN in a loop. Strict (!==) comparison catches X/Z.
//              Directed overlap streams, 2000 randomized bits, and an async-reset
//              spot-check run through one checked path. Prints only on mismatch.
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module SequenceDetector_tb;

    reg  clk, reset, din;
    wire det4, det3;

    SequenceDetector #(.LEN(4), .PATTERN(4'b1011)) dut4
        (.clk(clk), .reset(reset), .din(din), .detected(det4));
    SequenceDetector #(.LEN(3), .PATTERN(3'b101)) dut3
        (.clk(clk), .reset(reset), .din(din), .detected(det3));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer n      = 0;        // input bits clocked since the last reset
    integer i;
    reg     hist [1:5000];

    function h;
        input integer idx;
        begin
            if (idx >= 1) h = hist[idx];
            else          h = 1'b0;
        end
    endfunction

    // Independent detection: the trailing `len` bits (newest = h(n)) equal `pat`.
    // window[b] == h(n-b), and detected = (window == PATTERN), so the match is
    // the AND over b of (h(n-b) == pat[b]).
    function match;
        input integer len;
        input [7:0]   pat;
        reg     r;
        integer b;
        begin
            r = 1'b1;
            for (b = 0; b < len; b = b + 1)
                if (h(n-b) !== pat[b]) r = 1'b0;
            match = r;
        end
    endfunction

    task feed;
        input bit;
        reg e4, e3;
        begin
            @(negedge clk);
            din = bit;
            @(posedge clk);        // clock the bit into both windows
            n = n + 1;
            hist[n] = bit;
            #1;                    // let detected settle
            e4 = match(4, 8'b0000_1011);
            e3 = match(3, 8'b0000_0101);
            checks = checks + 2;
            if (det4 !== e4) begin
                errors = errors + 1;
                $display("  [%0t] DUT4(1011) MISMATCH n=%0d : det=%b expected=%b",
                         $time, n, det4, e4);
            end
            if (det3 !== e3) begin
                errors = errors + 1;
                $display("  [%0t] DUT3(101)  MISMATCH n=%0d : det=%b expected=%b",
                         $time, n, det3, e3);
            end
        end
    endtask

    task feed_str;
        input [8*32-1:0] s;
        integer k;
        reg [7:0] c;
        begin
            for (k = 31; k >= 0; k = k - 1) begin
                c = s[8*k +: 8];
                if (c == "0") feed(1'b0);
                else if (c == "1") feed(1'b1);
            end
        end
    endtask

    initial begin
        reset = 1'b1; din = 1'b0;
        @(negedge clk);
        @(negedge clk);
        reset = 1'b0; n = 0;

        feed_str("1011");          // single 1011 match
        feed_str("1011011");       // overlapping 1011
        feed_str("101101");        // overlaps for both patterns
        feed_str("0001011000");
        feed_str("10101010");      // dense 101 overlaps

        for (i = 0; i < 2000; i = i + 1)
            feed($random & 1);

        // Asynchronous-reset spot-check: load the windows, assert reset off a
        // clock edge, and confirm both detectors deassert (cleared windows).
        feed(1'b1); feed(1'b0); feed(1'b1); feed(1'b1);   // 1011 -> det4 == 1
        #2 reset = 1'b1;
        #1;
        checks = checks + 2;
        if (det4 !== 1'b0) begin
            errors = errors + 1;
            $display("  [%0t] async-reset: det4=%b expected 0", $time, det4);
        end
        if (det3 !== 1'b0) begin
            errors = errors + 1;
            $display("  [%0t] async-reset: det3=%b expected 0", $time, det3);
        end
        @(negedge clk); reset = 1'b0; n = 0;

        if (errors == 0)
            $display("SequenceDetector_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("SequenceDetector_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
