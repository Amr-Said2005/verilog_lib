// Mealy FSM to detect the sequence "101" with overlapping

module MealyFSM(
    input  wire clk,
    input  wire reset,
    input  wire in,
    output reg  out
);

    localparam [1:0]
        STATE_IDLE = 2'b00,
        STATE_A    = 2'b01,
        STATE_B    = 2'b10;

    reg [1:0] state, next_state;

    // State register (sequential)
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= STATE_IDLE;
        else
            state <= next_state;
    end

    // Next-state + output logic (combinational, Mealy)
    always @(*) begin
        next_state = state;   // default: no latch
        out        = 1'b0;    // default: no latch

case (state)
            STATE_IDLE: begin
                if (in) next_state = STATE_A;          // seen "1"
            end
            STATE_A: begin
                if (in) next_state = STATE_A;          // still "1"
                else    next_state = STATE_B;          // seen "10"
            end
            STATE_B: begin
                if (in) begin
                    next_state = STATE_A;              // "101" complete, overlap
                    out        = 1'b1;
                end else
                    next_state = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end
endmodule