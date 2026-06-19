// ----------------------------------------------------------------------------
// Testbench:   TimeCounter_tb
// DUT:         TimeCounter
// Description: Self-checking testbench for the HH:MM:SS time counter. The
//              reference model is independent of the DUT's nested rollover: it
//              keeps a single elapsed-seconds accumulator and derives the
//              expected time by modular arithmetic (s = t%60, m = (t/60)%60,
//              h = t/3600). One full 24-hour day plus the midnight wrap is swept
//              tick by tick (86,400+ ticks) with strict (!==) comparison, then a
//              count-hold (start low) phase and an async-reset-mid-count phase.
//              Prints only on mismatch; ends with a tally.
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module TimeCounter_tb;

    reg  clk = 1'b0;
    reg  start, rst;
    wire [5:0] Seconds, Minutes;
    wire [4:0] Hours;

    TimeCounter dut (.clk(clk), .start(start), .rst(rst),
                     .Seconds(Seconds), .Minutes(Minutes), .Hours(Hours));

    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer tsec   = 0;        // independent elapsed-seconds accumulator
    integer i;

    task check;
        reg [5:0] es, em;
        reg [4:0] eh;
        begin
            es = tsec % 60;
            em = (tsec / 60) % 60;
            eh = tsec / 3600;
            checks = checks + 3;
            if (Seconds !== es || Minutes !== em || Hours !== eh) begin
                errors = errors + 1;
                $display("  [%0t] t=%0d  DUT=%0d:%0d:%0d  expected=%0d:%0d:%0d",
                         $time, tsec, Hours, Minutes, Seconds, eh, em, es);
            end
        end
    endtask

    initial begin
        start = 1'b0; rst = 1'b1;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0; tsec = 0;
        @(negedge clk); start = 1'b1;

        // Full day + wrap past midnight, tick by tick.
        for (i = 0; i < 86405; i = i + 1) begin
            @(posedge clk);
            tsec = (tsec + 1) % 86400;
            #1; check;
        end

        // Hold: start low freezes the count.
        @(negedge clk); start = 1'b0;
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk); #1; check;          // tsec unchanged -> DUT must hold
        end
        @(negedge clk); start = 1'b1;

        // Advance a few ticks, then assert reset off a clock edge.
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk); tsec = (tsec + 1) % 86400; #1; check;
        end
        #2 rst = 1'b1; #1;
        checks = checks + 1;
        if (Seconds !== 0 || Minutes !== 0 || Hours !== 0) begin
            errors = errors + 1;
            $display("  [%0t] async-reset: DUT=%0d:%0d:%0d expected 0:0:0",
                     $time, Hours, Minutes, Seconds);
        end
        tsec = 0;
        @(negedge clk); rst = 1'b0;

        // Confirm it resumes from 00:00:00.
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk); tsec = (tsec + 1) % 86400; #1; check;
        end

        if (errors == 0)
            $display("TimeCounter_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("TimeCounter_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
