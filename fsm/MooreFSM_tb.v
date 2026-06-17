// ----------------------------------------------------------------------------
// Testbench:   MooreFSM_tb
// DUT:         MooreFSM
// Description: Self-checking testbench for the Moore "101" overlapping sequence
//              detector. The reference model is structurally independent: it
//              records the full input history and recomputes the expected
//              (registered) output from the three most-recently-clocked bits,
//              checked one cycle after each bit is clocked to match the Moore
//              latency. Strict (!==) comparison catches X/Z. Directed overlap
//              streams, 2000 randomized bits, and an async-reset spot-check are
//              driven through one checked path. Prints only on mismatch.
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module MooreFSM_tb;

    reg  clk, reset, in;
    wire out;

    MooreFSM dut (.clk(clk), .reset(reset), .in(in), .out(out));

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

    // Drive one bit, clock it in, then check the Moore output (registered):
    // out = 1  iff  the last three clocked bits are "101".
    task feed;
        input b;
        reg e;
        begin
            @(negedge clk);
            in = b;
            @(posedge clk);        // clock the bit -> state (and out) update
            n = n + 1;
            hist[n] = b;
            #1;                    // let the Moore output settle
            e = (h(n) === 1'b1) && (h(n-1) === 1'b0) && (h(n-2) === 1'b1);
            checks = checks + 1;
            if (out !== e) begin
                errors = errors + 1;
                $display("  [%0t] MISMATCH n=%0d : out=%b expected=%b",
                         $time, n, out, e);
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
        reset = 1'b1; in = 1'b0;
        @(negedge clk);
        @(negedge clk);
        reset = 1'b0; n = 0;

        feed_str("101");
        feed_str("10101");
        feed_str("1101011101");
        feed_str("000111000");
        feed_str("10101010101");

        for (i = 0; i < 2000; i = i + 1)
            feed($random & 1);

        // Asynchronous-reset spot-check: reach the MATCH state, then assert
        // reset off a clock edge and confirm the registered output clears.
        feed(1'b1); feed(1'b0); feed(1'b1);   // "101" -> out should be 1 here
        checks = checks + 1;
        if (out !== 1'b1) begin
            errors = errors + 1;
            $display("  [%0t] pre-reset: out=%b expected 1", $time, out);
        end
        #2 reset = 1'b1;            // async assert between edges
        #1;
        checks = checks + 1;
        if (out !== 1'b0) begin
            errors = errors + 1;
            $display("  [%0t] async-reset: out=%b expected 0", $time, out);
        end
        @(negedge clk); reset = 1'b0; n = 0;

        if (errors == 0)
            $display("MooreFSM_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("MooreFSM_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
