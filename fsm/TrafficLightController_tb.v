// ----------------------------------------------------------------------------
// Testbench:   TrafficLightController_tb
// DUT:         TrafficLightController
// Description: Self-checking testbench for the two-road traffic light FSM.
//              Test A (free-running, sensor low): the reference model is an
//              independent modular cycle counter — it derives the expected phase
//              from (cycle mod period) and threshold comparisons, structurally
//              unlike the DUT's incremental timer — and compares both light
//              vectors every cycle with strict (!==) checks over three full
//              periods. Every cycle also asserts two safety invariants: each
//              road shows exactly one valid R/Y/G code, and the two roads are
//              never simultaneously non-red. Test B verifies the sensor cuts the
//              main-green phase short. Test C verifies asynchronous reset forces
//              main-green / side-red immediately, off a clock edge.
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module TrafficLightController_tb;

    localparam GT = 10;        // GREEN_TICKS  (DUT defaults)
    localparam YT = 3;         // YELLOW_TICKS
    localparam P  = 2*GT + 2*YT;

    localparam [2:0] RED = 3'b100, YELLOW = 3'b010, GREEN = 3'b001;

    reg        clk, reset, sensor;
    wire [2:0] main_light, side_light;

    TrafficLightController #(.GREEN_TICKS(GT), .YELLOW_TICKS(YT), .CNT_WIDTH(4)) dut
        (.clk(clk), .reset(reset), .sensor(sensor),
         .main_light(main_light), .side_light(side_light));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer mcyc   = 0;        // cycles since reset (reference counter)
    integer i;
    reg [2:0] em, es;          // expected main / side lights

    // Independent reference counter, clocked exactly like the DUT.
    always @(posedge clk or posedge reset) begin
        if (reset) mcyc <= 0;
        else       mcyc <= mcyc + 1;
    end

    // Safety + encoding invariants — independent of the reference model.
    task check_invariants;
        begin
            checks = checks + 1;
            if (!(main_light == RED || main_light == YELLOW || main_light == GREEN)) begin
                errors = errors + 1;
                $display("  [%0t] INVARIANT main_light invalid = %b", $time, main_light);
            end
            checks = checks + 1;
            if (!(side_light == RED || side_light == YELLOW || side_light == GREEN)) begin
                errors = errors + 1;
                $display("  [%0t] INVARIANT side_light invalid = %b", $time, side_light);
            end
            // Never both non-red (no conflicting go/caution).
            checks = checks + 1;
            if (main_light != RED && side_light != RED) begin
                errors = errors + 1;
                $display("  [%0t] INVARIANT both roads non-red: main=%b side=%b",
                         $time, main_light, side_light);
            end
        end
    endtask

    // Test A reference: expected lights from the modular phase.
    task check_phase;
        input integer c;
        reg [31:0] m;
        begin
            m = c % P;
            if      (m < GT)        begin em = GREEN;  es = RED;    end
            else if (m < GT+YT)     begin em = YELLOW; es = RED;    end
            else if (m < 2*GT+YT)   begin em = RED;    es = GREEN;  end
            else                    begin em = RED;    es = YELLOW; end

            checks = checks + 2;
            if (main_light !== em) begin
                errors = errors + 1;
                $display("  [%0t] cyc=%0d main=%b expected=%b", $time, c, main_light, em);
            end
            if (side_light !== es) begin
                errors = errors + 1;
                $display("  [%0t] cyc=%0d side=%b expected=%b", $time, c, side_light, es);
            end
        end
    endtask

    initial begin
        // ---------------- Test A: free-running, sensor low ----------------
        sensor = 1'b0;
        reset  = 1'b1;
        @(negedge clk);
        @(negedge clk);
        reset = 1'b0;

        for (i = 0; i < 3*P + 5; i = i + 1) begin
            @(negedge clk);
            check_phase(mcyc);
            check_invariants;
        end

        // ---------------- Test B: sensor ends main-green early ----------------
        reset = 1'b1; @(negedge clk); @(negedge clk); reset = 1'b0;
        @(negedge clk);                       // cycle 1 (main green)
        @(negedge clk);                       // cycle 2
        @(negedge clk);                       // cycle 3 — well before GT=10
        checks = checks + 1;
        if (main_light !== GREEN) begin
            errors = errors + 1;
            $display("  [%0t] Test B: expected main GREEN before sensor, got %b",
                     $time, main_light);
        end
        sensor = 1'b1;                        // assert on negedge: stable across the coming posedge
        @(negedge clk);                       // the intervening posedge samples sensor -> early transition
        sensor = 1'b0;                        // deassert on negedge (no race with the sampling edge)
        checks = checks + 2;
        if (main_light !== YELLOW) begin
            errors = errors + 1;
            $display("  [%0t] Test B: sensor did not end green early, main=%b",
                     $time, main_light);
        end
        if (side_light !== RED) begin
            errors = errors + 1;
            $display("  [%0t] Test B: side not RED during main yellow, side=%b",
                     $time, side_light);
        end

        // ---------------- Test C: asynchronous reset ----------------
        reset = 1'b1; @(negedge clk); @(negedge clk); reset = 1'b0;
        repeat (15) @(negedge clk);           // advance into the side-green phase
        #2 reset = 1'b1;                      // assert reset off a clock edge
        #1;
        checks = checks + 2;
        if (main_light !== GREEN) begin
            errors = errors + 1;
            $display("  [%0t] Test C: async reset, main=%b expected GREEN", $time, main_light);
        end
        if (side_light !== RED) begin
            errors = errors + 1;
            $display("  [%0t] Test C: async reset, side=%b expected RED", $time, side_light);
        end
        @(negedge clk); reset = 1'b0;

        if (errors == 0)
            $display("TrafficLightController_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("TrafficLightController_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
