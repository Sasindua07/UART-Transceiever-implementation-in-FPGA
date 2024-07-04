module transmitter(
    input wire [7:0] data_in, // Input data
    input wire wr_en,         // Write enable
    input wire clk_50m,       // 50 MHz clock
    input wire clken,         // Clock enable for controlling transmission timing
    output reg Tx,            // Transmit output bit
    output wire Tx_busy       // Transmitter busy status indicator
);

// Initialize Tx to 1 to idle the line when not transmitting
initial begin
    Tx = 1'b1;
end

// State definitions
parameter TX_STATE_IDLE   = 2'b00;
parameter TX_STATE_START  = 2'b01;
parameter TX_STATE_DATA   = 2'b10;
parameter TX_STATE_STOP   = 2'b11;

// Internal state registers
reg [7:0] data = 8'h00;
reg [2:0] bit_pos = 3'h0;
reg [1:0] state = TX_STATE_IDLE;

// State machine handling transmission logic
always @(posedge clk_50m) begin
    case (state)
        TX_STATE_IDLE: begin
            if (~wr_en) begin
                state <= TX_STATE_START;
                data <= data_in;
                bit_pos <= 3'h0;
            end
        end
        TX_STATE_START: begin
            if (clken) begin
                Tx <= 1'b0; // Start bit
                state <= TX_STATE_DATA;
            end
        end
        TX_STATE_DATA: begin
            if (clken) begin
                Tx <= data[bit_pos];
                bit_pos <= bit_pos + 3'h1;
                if (bit_pos == 3'h7) state <= TX_STATE_STOP;
            end
        end
        TX_STATE_STOP: begin
            if (clken) begin
                Tx <= 1'b1; // Stop bit
                state <= TX_STATE_IDLE;
            end
        end
        default: begin
            Tx <= 1'b1;
            state <= TX_STATE_IDLE;
        end
    endcase
end

// Busy signal is active when not in idle state
assign Tx_busy = (state != TX_STATE_IDLE);

endmodule