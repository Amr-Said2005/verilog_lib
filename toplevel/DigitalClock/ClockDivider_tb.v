// ----------------------------------------------------------------------------
// Testbench:   ClockDivider_tb
// DUT:         ClockDivider  (two parameterizations)
// Description: Self-checking testbench for the integer clock divider. Two DUTs
//              (divide-by-4 and divide-by-7) share one input clock. The
//              reference model is independent of the DUT's incremental counter:
//              it derives the expected output from a free-running input-cycle
//              count as (cycles / DIVISOR) mod 2 — a perfect square wave —
//              checked every cycle with strict (!==) comparison. An async-reset
//              spot-check confirms the output clears off a clock edge. Prints
//              only on mismatch; ends with a tally.
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module ClockDivider_tb;

    localparam N4 = 4;
    localparam N7 = 7;

    reg  clk = 1'b0;
    reg  rst;
    wire out4, out7;

    ClockDivider #(.DIVISOR(N4)) d4 (.clk_in(clk), .rst(rst), .clk_out(out4));
    ClockDivider #(.DIVISOR(N7)) d7 (.clk_in(clk), .rst(rst), .clk_out(out7));

    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer k      = 0;        // input cycles since the last reset
    integer i;

    task check;
        reg e4, e7;
        begin
            e4 = (k / N4) % 2;
            e7 = (k / N7) % 2;
            checks = checks + 2;
            if (out4 !== e4) begin
                errors = errors + 1;
                $display("  [%0t] DIVISOR=4 k=%0d out=%b expected=%b", $time, k, out4, e4);
            end
            if (out7 !== e7) begin
                errors = errors + 1;
                $display("  [%0t] DIVISOR=7 k=%0d out=%b expected=%b", $time, k, out7, e7);
            end
        end
    endtask

    initial begin
        rst = 1'b1;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0; k = 0;

        for (i = 0; i < 400; i = i + 1) begin
            @(posedge clk); k = k + 1;
            @(negedge clk); check;
        end

        // Asynchronous reset off a clock edge: both outputs must clear.
        #2 rst = 1'b1;
        #1;
        checks = checks + 2;
        if (out4 !== 1'b0) begin errors = errors + 1; $display("  [%0t] async-reset out4=%b", $time, out4); end
        if (out7 !== 1'b0) begin errors = errors + 1; $display("  [%0t] async-reset out7=%b", $time, out7); end
        @(negedge clk); rst = 1'b0; k = 0;

        for (i = 0; i < 60; i = i + 1) begin
            @(posedge clk); k = k + 1;
            @(negedge clk); check;
        end

        if (errors == 0)
            $display("ClockDivider_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("ClockDivider_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
