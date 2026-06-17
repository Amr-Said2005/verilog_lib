// ----------------------------------------------------------------------------
// Module:      TrafficLightController
// Description: Two-direction traffic light controller built as a Moore FSM with
//              four phases: main-green, main-yellow, side-green, side-yellow.
//              Each green phase lasts GREEN_TICKS clocks and each yellow phase
//              YELLOW_TICKS clocks; the two roads are never green together. The
//              light outputs are a pure function of the phase (Moore). A side-
//              road `sensor` request ends the MAIN-GREEN phase early: when it is
//              asserted during main-green the controller advances to main-yellow
//              on the next clock instead of waiting out the full green time.
//              Light vectors are 3-bit {Red, Yellow, Green} (bit2=Red, bit1=
//              Yellow, bit0=Green); exactly one bit is high per road at a time.
// Parameters:  GREEN_TICKS  - green phase duration in clock cycles (default 10)
//              YELLOW_TICKS - yellow phase duration in clock cycles (default 3)
//              CNT_WIDTH    - phase-timer counter width (default 4)
// Ports:       clk        - input clock (rising edge)
//              reset      - asynchronous reset, active high (starts main green)
//              sensor     - side-road vehicle/pedestrian request
//              main_light - 3-bit {Red, Yellow, Green} for the main road
//              side_light - 3-bit {Red, Yellow, Green} for the side road
// Author:      Amr Said
// Date:        2026-06-17
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
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

    // Light codes: {Red, Yellow, Green}
    localparam [2:0] RED    = 3'b100,
                     YELLOW = 3'b010,
                     GREEN  = 3'b001;

    // Phases
    localparam [1:0] MAIN_GREEN  = 2'd0,
                     MAIN_YELLOW = 2'd1,
                     SIDE_GREEN  = 2'd2,
                     SIDE_YELLOW = 2'd3;

    reg [1:0]           state;
    reg [CNT_WIDTH-1:0] tick;   // cycles elapsed in the current phase

    // Phase + timer register (sequential, asynchronous reset to MAIN_GREEN)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= MAIN_GREEN;
            tick  <= {CNT_WIDTH{1'b0}};
        end else begin
            case (state)
                MAIN_GREEN:
                    // End early on a side-road request, else run the full green.
                    if (sensor || tick == GREEN_TICKS - 1) begin
                        state <= MAIN_YELLOW;
                        tick  <= {CNT_WIDTH{1'b0}};
                    end else
                        tick <= tick + 1'b1;
                MAIN_YELLOW:
                    if (tick == YELLOW_TICKS - 1) begin
                        state <= SIDE_GREEN;
                        tick  <= {CNT_WIDTH{1'b0}};
                    end else
                        tick <= tick + 1'b1;
                SIDE_GREEN:
                    if (tick == GREEN_TICKS - 1) begin
                        state <= SIDE_YELLOW;
                        tick  <= {CNT_WIDTH{1'b0}};
                    end else
                        tick <= tick + 1'b1;
                SIDE_YELLOW:
                    if (tick == YELLOW_TICKS - 1) begin
                        state <= MAIN_GREEN;
                        tick  <= {CNT_WIDTH{1'b0}};
                    end else
                        tick <= tick + 1'b1;
            endcase
        end
    end

    // Output logic (Moore: lights depend only on the current phase)
    always @(*) begin
        case (state)
            MAIN_GREEN:  begin main_light = GREEN;  side_light = RED;    end
            MAIN_YELLOW: begin main_light = YELLOW; side_light = RED;    end
            SIDE_GREEN:  begin main_light = RED;    side_light = GREEN;  end
            SIDE_YELLOW: begin main_light = RED;    side_light = YELLOW; end
            default:     begin main_light = RED;    side_light = RED;    end
        endcase
    end

endmodule
