module uart_TB();

reg [7:0] data = 0;   // Data to be transmitted
reg clk = 0;          // Clock signal
reg enable = 0;       // Enable signal for UART transmission

wire Tx_busy;         // UART transmitter busy signal
wire rx_ready;        // Signal indicating data is ready to be read from receiver
wire [7:8] rx_data;   // Data received by UART

wire loopback;
reg ready_clr = 0;

uart test_uart(.data_in(data),
					.wr_en(enable),
					.clk_50m(clk),
					.Tx(loopback),
					.Tx_busy(Tx_busy),
					.Rx(loopback),
					.ready(ready),
					.ready_clr(ready_clr),
					.data_out(Rx_data)
					);
					
// Generate the clock with a period of 2 time units	
				
initial begin
	$dumpfile("uart.vcd");
	$dumpvars(0, uart_TB);
	enable <= 1'b1;
	#2 enable <= 1'b0;
end

always begin
	#1 clk = ~clk;         // Toggle clock every 1 time unit
end

always @(posedge ready) begin
	#2 ready_clr <= 1;
	#2 ready_clr <= 0;
	
	if (Rx_data!= data) begin
		$display("FAIL", Rx_data, data);
		$finish;
	end 
	
	else begin
		if (Rx_data == 8'h2) begin // Stop after the last byte
			$display("SUCCESS: all bytes verified");
			$finish;
		end
		data <= data + 1'b1;
		enable <= 1'b1;
		#2 enable <= 1'b0;
	end
end
endmodule
