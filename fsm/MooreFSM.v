// ----------------------------------------------------------------------------
// Module:      MooreFSM
// Description: Generic Moore finite state machine template. Outputs depend
//              only on the current state, not on inputs — making them glitch-
//              free and registered by construction. Suitable for control units,
//              traffic lights, and any design where output stability matters.
// Parameters:  (user-defined — add states and transitions for your application)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high
//              in    - single-bit input stimulus
//              out   - single-bit Moore output (function of state only)
// Author:      Amr Said
// Date:        2026-06-10
// ----------------------------------------------------------------------------
module MooreFSM(
    input  clk,
    input  reset,
    input  in,
    output reg out
);

    
endmodule
