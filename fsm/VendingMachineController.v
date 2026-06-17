// ----------------------------------------------------------------------------
// Module:      VendingMachineController
// Description: Simple coin-operated vending machine FSM. Accepts nickels (5¢)
//              and dimes (10¢), dispenses product when accumulated total
//              reaches or exceeds PRICE, and returns change if overpaid.
//              Uses a Moore FSM with one state per accumulated-value level.
// Parameters:  PRICE - item price in cents (default 15)
// Ports:       clk      - input clock (rising edge)
//              reset    - asynchronous reset, active high (returns to IDLE)
//              nickel   - pulse high for one cycle when nickel inserted
//              dime     - pulse high for one cycle when dime inserted
//              dispense - asserts for one cycle when product is dispensed
//              change   - asserts for one cycle when change is returned
// Author:      Amr Said
// Date:        2026-06-10
// ----------------------------------------------------------------------------
module VendingMachineController #(
    parameter PRICE = 15
)(
    input  clk,
    input  reset,
    input  nickel,
    input  dime,
    output reg dispense,
    output reg change
);
endmodule
