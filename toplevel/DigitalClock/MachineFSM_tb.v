// ----------------------------------------------------------------------------
// Testbench:   MachineFSM_tb
// DUT:         MachineFSM
// Description: Self-checking testbench for the time-of-day mode FSM. The
//              reference is an independent zone function mapping Hours -> mode
//              (IDLE 0-7, STARTING 8-9, WORKING 10-23). Because the DUT
//              re-decodes all zones every state, after one clock the state must
//              equal zone(Hours) regardless of the prior state — this is checked
//              for every hour 0..23, for randomized hours, and after resets at
//              arbitrary hours (verifying correct recovery). Strict (!==)
//              comparison; prints only on mismatch; ends with a tally.
// Author:      Amr Said
// Date:        2026-06-19
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module MachineFSM_tb;

    localparam [1:0] IDLE = 2'b00, STARTING = 2'b01, WORKING = 2'b10;

    reg        clk = 1'b0;
    reg        rst;
    reg  [4:0] Hours;
    wire [1:0] state;

    MachineFSM dut (.clk(clk), .rst(rst), .Hours(Hours), .state(state));

    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer i;

    function [1:0] zone;
        input [4:0] h;
        begin
            if      (h >= 5'd10) zone = WORKING;
            else if (h >= 5'd8)  zone = STARTING;
            else                 zone = IDLE;
        end
    endfunction

    // Set an hour, clock it, and check state == zone(hour).
    task set_hour;
        input [4:0] h;
        reg [1:0] e;
        begin
            @(negedge clk); Hours = h;
            @(posedge clk); #1;
            e = zone(h);
            checks = checks + 1;
            if (state !== e) begin
                errors = errors + 1;
                $display("  [%0t] Hours=%0d state=%b expected=%b", $time, h, state, e);
            end
        end
    endtask

    initial begin
        rst = 1'b1; Hours = 5'd0;
        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;

        // Every hour, in order (exercises all zone transitions).
        for (i = 0; i <= 23; i = i + 1) set_hour(i[4:0]);
        // ...and in reverse.
        for (i = 23; i >= 0; i = i - 1) set_hour(i[4:0]);

        // Randomized hours 0..23.
        for (i = 0; i < 500; i = i + 1) set_hour(({$random} % 24));

        // Reset at an arbitrary hour must go to IDLE, then re-decode correctly.
        @(negedge clk); Hours = 5'd15;          // would be WORKING
        #2 rst = 1'b1; #1;
        checks = checks + 1;
        if (state !== IDLE) begin
            errors = errors + 1;
            $display("  [%0t] async-reset: state=%b expected IDLE", $time, state);
        end
        @(negedge clk); rst = 1'b0;
        set_hour(5'd15);                          // one clock later -> WORKING
        checks = checks + 1;
        if (state !== WORKING) begin
            errors = errors + 1;
            $display("  [%0t] post-reset decode: state=%b expected WORKING", $time, state);
        end

        if (errors == 0)
            $display("MachineFSM_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("MachineFSM_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
