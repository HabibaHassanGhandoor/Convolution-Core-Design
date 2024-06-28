module fifo_controller (input clk,rst,fifo_empty,
                        input [7:0] output_size,
                        input size_valid,
                        input [31:0] fifo_data,
                        output reg [127:0]  Dataout,
                        output reg valid,fifo_en,
                        output done);
                        
reg [2:0] counter; // counts 4 word and put them on 128-bit bus
reg [15:0] word_count; // total number of words of output
wire [15:0] word_count_tmp; 
wire [1:0] remainder ; // if word count not divisible by 4, so but data on bus and conctenate it with zeros
reg [2:0] WAIT; // to wait 1 clock cycle after asserting fifo_en to get data out from FIFO
reg delay_valid; // to make sure valid is asserted in case remiander = 1
assign word_count_tmp = output_size * output_size; // to get total number of elements of output matrix
assign remainder = word_count_tmp % 4 ;
assign done = (word_count == 0)? 1'b1:1'b0; // to assert done when finish generating output


always @ (posedge clk or negedge rst)
begin
  	if (~rst) begin
      	counter <= 3'b0;
      	Dataout <= 128'b0;
      	WAIT <= 0;
      	delay_valid <= 0;
    end
  	else begin
    	word_count <= (size_valid)? word_count_tmp:word_count;
      	if (delay_valid==1'b1) begin
        	delay_valid <= 0;
        end
      	if (~fifo_empty) begin
			if ((word_count >= 'd4)) begin
				if (counter <= 3'd4) begin
					counter <= counter + 1;
				end
				else begin
					counter <= 3'b0;
					word_count <= word_count - 'd4; //4 words of output are on the 128-bit bus
				end  
			end		
		end
		else begin
			if (counter == 'd4 ) begin //FIFO empty (to make sure after getting 4 words reset counter and minus word count even if FIFO empty)
          		counter <= 3'b0;
				word_count <= word_count - 'd4;
			end
      		else begin
      			counter <= counter;
      		end
		end
	end
end

always @ (*)
begin
if ((word_count < 'd4)   && (~fifo_empty)) // there is remainder, conctenation is needed
begin
  fifo_en = 1;
	if (remainder == 2'd1) begin
		if (WAIT == 'd1) begin
			Dataout <= {96'b0,fifo_data};
		   	word_count = word_count-1;
		   	WAIT <= 0;
		   	delay_valid = delay_valid+1;
		    end
		else begin 
			WAIT = WAIT+1;
		end
	end
end
else if (delay_valid == 1'b1 && remainder==1'b1) begin
		valid = 1'b1; // to insert valid with Dataout of remiander = 1
end
else begin
	if (counter == 2'd0) begin //if fifo empty not asserted, assert fifo_en to get fifo_data the next clock cycle 
		if (~fifo_empty)begin
			fifo_en <= 1'b1;
		end
		else begin
			fifo_en <= 1'b0;
		end
		valid <= 1'b0;
	end
	else if (counter == 2'd1) begin
			fifo_en <= 1'b1; 
		  	Dataout [31:0] <= fifo_data;
		   	valid <= 1'b0;
	end
	else if (counter == 2'd2) begin
			fifo_en <= 1'b1;
		  	Dataout [63:32] <= fifo_data;
		   	valid <= 1'b0;
	end
	else if (counter == 2'd3) begin 
			fifo_en <= 1'b1;
		  	Dataout [95:64] <= fifo_data;
		   	valid <= 1'b0;
	end		
 	else begin
    	fifo_en <= 1'b0;
 		Dataout [127:96] <= fifo_data;
	  	valid <= 1'b1; // Dataout valid (4 words of output are on 128-bit bus)
  	end
	 
end	
end
endmodule



