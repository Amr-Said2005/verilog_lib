// ----------------------------------------------------------------------------
// Module:      VendingMachineController
// Description: Coin-operated vending machine FSM. Accepts nickels (5c) and dimes
//              (10c), dispenses product once the accumulated credit reaches or
//              exceeds PRICE, and returns change when the final coin overpays.
//              The accumulated credit register is the machine state (one level
//              per reachable 5c step), making this a Moore machine; `dispense`
//              and `change` are registered single-cycle pulses asserted the
//              cycle after the coin that triggers them, and the credit clears
//              back to zero on a sale. At most one coin is accepted per clock
//              (if both nickel and dime are asserted, the dime takes priority).
// Parameters:  PRICE - item price in cents (default 15)
// Ports:       clk      - input clock (rising edge)
//              reset    - asynchronous reset, active high (returns to IDLE/0c)
//              nickel   - pulse high for one cycle when a nickel is inserted
//              dime     - pulse high for one cycle when a dime is inserted
//              dispense - pulses high for one cycle when product is dispensed
//              change   - pulses high for one cycle when change is returned
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module VendingMachineController #(
    parameter PRICE = 15
)(
    input      clk,
    input      reset,
    input      nickel,
    input      dime,
    output reg dispense,
    output reg change
);

    // Width wide enough to hold credit plus one more dime before a sale clears
    // it (worst case ~ PRICE + 5).
    localparam ACC_WIDTH = $clog2(PRICE + 11);

    reg [ACC_WIDTH-1:0] credit;        // accumulated credit in cents (the state)
    reg [ACC_WIDTH-1:0] coin, total;   // combinational intermediates

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            credit   <= {ACC_WIDTH{1'b0}};
            dispense <= 1'b0;
            change   <= 1'b0;
        end else begin
            // Defaults: pulses are deasserted unless a sale happens this cycle.
            dispense <= 1'b0;
            change   <= 1'b0;

            coin = dime ? 5'd10 : (nickel ? 5'd5 : 5'd0);
            if (coin != 0) begin
                total = credit + coin;
                if (total >= PRICE) begin
                    dispense <= 1'b1;            // product out
                    if (total > PRICE)
                        change <= 1'b1;          // overpaid — return change
                    credit <= {ACC_WIDTH{1'b0}}; // reset for the next sale
                end else begin
                    credit <= total;             // keep accumulating
                end
            end
        end
    end

endmodule
