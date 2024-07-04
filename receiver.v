module receiver (
    input wire Rx,
    output reg ready,          // Indicates data is ready
    input wire ready_clr,      // Clear the ready signal
    input wire clk_50m,        // 50 MHz clock
    input wire clken,          // Clock enable for controlling reception timing
    output reg [7:0] data      // Received data output
);

// Initialize default states and data
initial begin
    ready = 1'b0; // Ready flag cleared
    data = 8'b0;  // Data cleared
end

// Receiver states
parameter RX_STATE_START = 2'b00;
parameter RX_STATE_DATA  = 2'b01;
parameter RX_STATE_STOP  = 2'b10;

// Internal state registers
reg [1:0] state = RX_STATE_START;
reg [3:0] sample = 0;      // Bit sampling counter
reg [3:0] bit_pos = 0;     // Position in the data byte
reg [7:0] scratch = 8'b0;  // Temporary storage for the received bits

// Receiver state machine
always @(posedge clk_50m) begin
    if (ready_clr)
        ready <= 1'b0; // Reset ready flag

    if (clken) begin
        case (state)
            RX_STATE_START: begin
                if (!Rx || sample != 0) // Check for start bit
                    sample <= sample + 1;
                if (sample == 15) begin // Full start bit sampled
                    state <= RX_STATE_DATA;
                    bit_pos <= 0;
                    sample <= 0;
                    scratch <= 0;
                end
            end
            RX_STATE_DATA: begin
                sample <= sample + 1;
                if (sample == 8) begin // Middle of data bit sampling
                    scratch[bit_pos[2:0]] <= Rx; // Store received bit
                    bit_pos <= bit_pos + 1;
                end
                if (bit_pos == 8 && sample == 15) // Full byte received
                    state <= RX_STATE_STOP;
            end
            RX_STATE_STOP: begin
                // Check for complete stop bit
                if (sample == 15 || (sample >= 8 && !Rx)) begin
                    state <= RX_STATE_START;
                    data <= scratch;  // Transfer received byte
                    ready <= 1'b1;    // Signal that data is ready
                    sample <= 0;
                end else begin
                    sample <= sample + 1;
                end
            end
            default: begin
                state <= RX_STATE_START; // Reset to start state in case of an undefined state
            end
        endcase
    end
end

endmodule