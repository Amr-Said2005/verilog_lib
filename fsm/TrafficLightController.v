// ----------------------------------------------------------------------------
// Module:      TrafficLightController
// Description: Two-direction traffic light controller using a Moore FSM.
//              Cycles through Green → Yellow → Red for each direction with
//              configurable timing. A pedestrian/sensor input can request an
//              early phase change. Outputs drive 3-bit light vectors
//              (Red-Yellow-Green) for the main and side roads.
// Parameters:  GREEN_TICKS  - green phase duration in clock cycles (default 10)
//              YELLOW_TICKS - yellow phase duration in clock cycles (default 3)
//              CNT_WIDTH    - timer counter width (default 4)
// Ports:       clk       - input clock (rising edge)
//              reset     - asynchronous reset, active high (starts main green)
//              sensor    - side-road vehicle/pedestrian request
//              main_light - 3-bit output {Red, Yellow, Green} for main road
//              side_light - 3-bit output {Red, Yellow, Green} for side road
// Author:      Amr Said
// Date:        2026-06-10
// ----------------------------------------------------------------------------
module TrafficLightController #(
    parameter GREEN_TICKS  = 10,
    parameter YELLOW_TICKS = 3,
    parameter CNT_WIDTH    = 4
)(
    input            clk,
    input            reset,
    input            sensor,
    output reg [2:0] main_light,
    output reg [2:0] side_light
);
endmodule
