// ----------------------------------------------------------------------------
// Testbench:   MealyFSM_tb
// DUT:         MealyFSM
// Description: Self-checking testbench for the Mealy "101" overlapping sequence
//              detector. The reference model is structurally independent of the
//              DUT: instead of a 3-state enumerated FSM it records the full input
//              history in an array and recomputes the expected (combinational)
//              Mealy output directly from the two most-recently-clocked bits plus
//              the current input. Strict (!==) comparison flags any X/Z as well
//              as logical mismatches. Directed overlap streams, 2000 randomized
//              bits, and an asynchronous-reset spot-check are all driven through
//              the same checked path. Prints only on mismatch; ends with a tally.
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module MealyFSM_tb;

    reg  clk, reset, in;
    wire out;

    MealyFSM dut (.clk(clk), .reset(reset), .in(in), .out(out));

    // 100 MHz clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer n      = 0;        // input bits clocked since the last reset
    integer i;
    reg     hist [1:5000];     // recorded input history (independent reference)

    // History bit, treating positions before the start of the stream as 0
    // (mirrors the DUT's IDLE reset state).
    function h;
        input integer idx;
        begin
            if (idx >= 1) h = hist[idx];
            else          h = 1'b0;
        end
    endfunction

    // Expected Mealy output for input `b` given n bits already clocked:
    // out = 1  iff  the last two clocked bits were "1" then "0" (DUT state B)
    //               AND the current input is 1  ->  completes "101".
    function exp_out;
        input b;
        begin
            exp_out = (h(n-1) === 1'b1) && (h(n) === 1'b0) && (b === 1'b1);
        end
    endfunction

    // Drive one bit: check the combinational output this cycle, then clock it in.
    task feed;
        input b;
        reg e;
        begin
            @(negedge clk);
            in = b;
            #1;
            e = exp_out(b);
            checks = checks + 1;
            if (out !== e) begin
                errors = errors + 1;
                $display("  [%0t] MISMATCH n=%0d in=%b : out=%b expected=%b",
                         $time, n, b, out, e);
            end
            @(posedge clk);        // clock the bit into the DUT
            n = n + 1;
            hist[n] = b;
        end
    endtask

    // Feed a stream given as an ASCII-ish bit list passed via a string of 0/1.
    task feed_str;
        input [8*32-1:0] s;        // up to 32 chars
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

        // Directed overlap-heavy streams (MSB char fed first)
        feed_str("101");          // single match
        feed_str("10101");        // two overlapping matches
        feed_str("1101011101");   // mixed
        feed_str("000111000");    // no match
        feed_str("10101010101");  // many overlaps

        // Randomized stimulus
        for (i = 0; i < 2000; i = i + 1)
            feed($random & 1);

        // Asynchronous-reset spot-check: drive into a non-IDLE state, assert
        // reset off a clock edge, and confirm the output clears immediately.
        @(negedge clk); in = 1'b1; @(posedge clk); n = n + 1; hist[n] = 1'b1;
        @(negedge clk); in = 1'b0; @(posedge clk); n = n + 1; hist[n] = 1'b0;
        in = 1'b1;                 // would-be third bit of "101"
        #2 reset = 1'b1;           // async assert between edges
        #1;
        checks = checks + 1;
        if (out !== 1'b0) begin
            errors = errors + 1;
            $display("  [%0t] async-reset: out=%b expected 0", $time, out);
        end
        @(negedge clk); reset = 1'b0; n = 0;

        if (errors == 0)
            $display("MealyFSM_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("MealyFSM_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
