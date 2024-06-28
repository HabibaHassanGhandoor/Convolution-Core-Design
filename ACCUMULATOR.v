module Accumulator(
    input               clk, 
    input               rst,
    input    [31:0]     IN1,
    //input               clear,
    input               in_valid,
    input [7:0]         kernel_size,
    output reg [31:0]   Accumulator,
    output reg              output_valid
    );

wire [31:0] out;
wire [15:0] counter_tmp;
reg  [15:0] counter ;

assign counter_tmp = kernel_size*kernel_size;

always @(posedge clk or negedge rst) begin
    if(~rst) begin
        Accumulator <= 0;
        output_valid <= 0;
        counter <= 0;
    end

    else if (in_valid) begin
      counter <= counter + 1 ;
        if (counter == counter_tmp-1)
          begin
            counter <= 0;
            output_valid <= 1;
            Accumulator <= out;
          end
        else if (counter == 0)begin
          Accumulator <= 0;
          output_valid <= 0;
        end
       else
         begin
        
        Accumulator <= out;
        output_valid <= 0;
      
        
         end
          
    end
    else begin
      Accumulator <= out;
      output_valid <= 0;
      end
end
        Adder add_inst(
            .clk(clk),
            .rst(rst),
            .OperandA(IN1),
            .OperandB(Accumulator),
            .in_valid(in_valid),
            .Exception(),
            .zero_exponent(),
            .NaN(),
            .out_valid(),
            .out(out)
        );
      

endmodule 


