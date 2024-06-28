module floating_Mult(
    input               clk, 
    input               rst,
    input       [31:0]  OperandA,
    input       [31:0]  OperandB,
    input               in_valid,
    output              zero_exponent, // to check if mantissa product is already zero_exponent so no need for normalization
    output              Exception, // to handle special case i.e., exponent is 255, the value is infinity
    output              NaN, // if all operand = 1
    output reg          out_valid,
    output reg  [31:0]  out
);

    reg sign_out;
    reg normalize; // to check normalization
    reg [7:0] Exponent_out;
    reg [22:0] Mantissa_out;
    reg [23:0] OperandA_reg, OperandB_reg; // to set the implicit bit before multiplying
    reg [47:0] Mantissa_product;

    localparam BIAS = 127;

    always @(*) begin
        if(~rst) begin
            out = 32'b0;
            out_valid = 1'b0;
        end
        else if(in_valid) begin 

            // Calculating Sign
            sign_out = OperandA[31] ^ OperandB[31];

            // Calculating Mantissa
            //setting the implicit bit, it will be 1 unless exponent is 0
       		OperandA_reg = (|OperandA[30:23]) ? {1'b1, OperandA[22:0]} : {1'b0, OperandA[22:0]};
            OperandB_reg = (|OperandB[30:23]) ? {1'b1, OperandB[22:0]} : {1'b0, OperandB[22:0]};

            Mantissa_product = OperandA_reg * OperandB_reg;

            normalize = Mantissa_product[47]; // checking normalization

            if(~normalize && ~zero_exponent) begin
      			Mantissa_product = Mantissa_product << 1 ;
      			Mantissa_out = Mantissa_product[46:24] + Mantissa_product[23] ; //for rounding
      			normalize = Mantissa_product[47];
      			Exponent_out = (OperandA[30:23] + OperandB[30:23] - BIAS);
    		end
  			else begin
  				Mantissa_out = Mantissa_product [46:24]; // no rounding already normalized
  				Exponent_out = (OperandA[30:23] + OperandB[30:23] - BIAS) + normalize;
  			end

            if (zero_exponent) begin
                out = 32'b0;
                out_valid = 1'b1;
            end
            else if(NaN) begin
                out = {sign_out,8'b1111_1111, 23'b111_1111_1111_1111_1111_1111};
                out_valid = 1'b1;
            end
            else if(Exception) begin
                out = {sign_out,8'b1111_1111,23'b0};
                out_valid = 1'b1;
            end
            else if (normalize) begin
                out = {sign_out, Exponent_out, Mantissa_out};
                out_valid = 1'b1;
            end
        end
        else begin // ~in_valid
            out = 32'b0;
            out_valid = 1'b0;
        end
    end

    assign Exception = ( ( (&OperandA[30:23]) && (OperandA[22:0] == 0) )   || ( (&OperandB[30:23]) && (OperandB[22:0] == 0) ) ) ? 1'b1 : 1'b0;
    assign zero_exponent = ((OperandA[30:23] == 0) | (OperandB[30:23] == 0)) ? 1'b1 : 1'b0;
    assign NaN =( ( (OperandA[30:23] == 8'b1111_1111) && (OperandA [22:0] != 23'b0) ) || ( (OperandB[30:23] == 8'b1111_1111) && (OperandB [22:0] != 23'b0) ) ) ? 1 : 0; 


endmodule


