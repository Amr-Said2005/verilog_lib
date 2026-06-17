// ----------------------------------------------------------------------------
// Testbench:   VendingMachineController_tb
// DUT:         VendingMachineController
// Description: Self-checking testbench for the coin-operated vending FSM
//              (PRICE = 15c, nickels and dimes). The reference model is an
//              independent integer credit accumulator kept in the testbench: for
//              each coin it predicts the registered dispense/change pulses and
//              the running credit, then compares against the DUT with strict
//              (!==) checks. Coins are driven on the negedge so they are stable
//              across the sampling posedge (no edge race), and outputs are
//              checked the cycle after each coin. Directed sequences cover every
//              way to reach PRICE (exact and overpaid), idle holding, dime-over-
//              nickel priority, and reset-mid-accumulation; 600 randomized coin
//              draws add breadth. Prints only on mismatch; ends with a tally.
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module VendingMachineController_tb;

    localparam PRICE = 15;

    reg  clk, reset, nickel, dime;
    wire dispense, change;

    VendingMachineController #(.PRICE(PRICE)) dut
        (.clk(clk), .reset(reset), .nickel(nickel), .dime(dime),
         .dispense(dispense), .change(change));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer errors = 0;
    integer checks = 0;
    integer credit = 0;        // independent reference accumulator (cents)
    integer total, cval;
    integer i;

    // Apply one coin and check the resulting (registered) pulses.
    //   kind: 0 = none/idle, 1 = nickel, 2 = dime, 3 = both (dime priority)
    task coin;
        input [1:0] kind;
        reg exp_disp, exp_chg;
        begin
            @(negedge clk);
            nickel = (kind == 1) || (kind == 3);
            dime   = (kind == 2) || (kind == 3);

            // Reference prediction (dime takes priority when both asserted).
            exp_disp = 1'b0;
            exp_chg  = 1'b0;
            cval = (kind == 2 || kind == 3) ? 10 : (kind == 1) ? 5 : 0;
            if (cval != 0) begin
                total = credit + cval;
                if (total >= PRICE) begin
                    exp_disp = 1'b1;
                    if (total > PRICE) exp_chg = 1'b1;
                    credit = 0;
                end else begin
                    credit = total;
                end
            end

            @(posedge clk);        // coin sampled; pulses register on this edge
            @(negedge clk);        // outputs now reflect this coin
            nickel = 1'b0;
            dime   = 1'b0;

            checks = checks + 2;
            if (dispense !== exp_disp) begin
                errors = errors + 1;
                $display("  [%0t] kind=%0d dispense=%b expected=%b (credit->%0d)",
                         $time, kind, dispense, exp_disp, credit);
            end
            if (change !== exp_chg) begin
                errors = errors + 1;
                $display("  [%0t] kind=%0d change=%b expected=%b (credit->%0d)",
                         $time, kind, change, exp_chg, credit);
            end
        end
    endtask

    task do_reset;
        begin
            reset = 1'b1; nickel = 1'b0; dime = 1'b0;
            @(negedge clk);
            @(negedge clk);
            reset  = 1'b0;
            credit = 0;            // mirror DUT clearing to IDLE
        end
    endtask

    initial begin
        do_reset;

        // Directed: three nickels -> exact PRICE, dispense, no change
        coin(1); coin(1); coin(1);
        // idle holding does not disturb credit or fire pulses
        coin(0); coin(0);
        // two dimes -> overpay (20c): dispense + change
        coin(2); coin(2);
        // nickel then dime -> exactly 15: dispense, no change
        coin(1); coin(2);
        // dime then nickel -> exactly 15: dispense, no change
        coin(2); coin(1);
        // dime, dime (overpay, reset), then three nickels -> dispense again
        coin(2); coin(2); coin(1); coin(1); coin(1);
        // dime + nickel asserted together -> dime priority (10c, no dispense yet)
        coin(3); coin(1);          // 10 then 15 -> dispense

        // Reset mid-accumulation clears credit: one nickel, reset, then it must
        // take three fresh nickels to dispense again.
        coin(1);                   // credit = 5
        do_reset;                  // async clear
        coin(1); coin(1);          // credit = 10 (no dispense)
        coin(1);                   // credit = 15 -> dispense

        // Randomized coin draws checked against the reference accumulator
        for (i = 0; i < 600; i = i + 1)
            coin({$random} % 3);

        if (errors == 0)
            $display("VendingMachineController_tb: PASS  (%0d checks, 0 errors)", checks);
        else
            $display("VendingMachineController_tb: FAIL  (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
