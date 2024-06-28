module Adder(
    input               clk,
    input               rst,
    input       [31:0]  OperandA,
    input       [31:0]  OperandB,
    input               in_valid,
    output              Exception, // to handle special case i.e., exponent is 255, the value is infinity
    output              zero_exponent,
    output              NaN,
    //output reg          out_valid_result,
    //output reg     [31:0]        Result
    output reg out_valid,
   
output reg [31:0] out
    );

 //reg  [31:0]  out;
 //reg          out_valid;
//operandA format
reg signA;
reg [23:0] mantissaA;
reg [7:0] expA;
//operandB format
reg signB;
reg [23:0] mantissaB;
reg [7:0] expB, expB_new;

reg [24:0] mantissa_sum;
reg [23:0] mantissaB_shift;

//output format
reg sign_out;
reg [7:0] exp_out;
reg [22:0] mantissa_out;

///signals
reg [8:0] Diff_exponent; //difference between exponents


/*always @(posedge clk or negedge rst) begin
    if(~rst) begin
        Result <= 0;
        out_valid_result <=0;
    end else begin
        Result <= out;
        out_valid_result <= out_valid;
    end
end */
always @(*) begin
    //******operandA********//
    signA = OperandA [31];
    expA = OperandA [30:23];
    //setting the implicit bit, it will be 1 unless exponent is 0
    mantissaA = (|OperandA[30:23]) ? {1'b1, OperandA[22:0]} : {1'b0, OperandA[22:0]};

    //******operandB********//
    signB = OperandB [31];
    expB = OperandB [30:23];
    //setting the implicit bit, it will be 1 unless exponent is 0
    mantissaB = (|OperandB[30:23]) ? {1'b1, OperandB[22:0]} : {1'b0, OperandB[22:0]};

    if (~rst) begin
        out = 32'b0;
        out_valid = 1'b0;
    end
    else if(in_valid) begin

       if (expA < expB) begin
            // Swap OperandA and OperandB, oPerand A always has larger exponent//
            {signA, expA, mantissaA, signB, expB, mantissaB} = {signB, expB, mantissaB, signA, expA, mantissaA};
        end

        ////////adjust exponent of OperandB//////////////////
        Diff_exponent = expA - expB ;
        expB_new = expB + Diff_exponent ;
        mantissaB_shift = (Diff_exponent > 0) ? mantissaB >> Diff_exponent : mantissaB ;
        exp_out = expA;
        //Add Mantissas///
        if(signA == signB) begin
            mantissa_sum = mantissaA + mantissaB_shift;
            sign_out = signA;
        end
        else begin
        if(mantissaA >= mantissaB_shift) begin
            mantissa_sum = mantissaA - mantissaB_shift;
            sign_out = signA;
        end
        else begin
            mantissa_sum = mantissaB_shift - mantissaA;
            sign_out = signB ;
        end
        end

        //check carry
        if(mantissa_sum[24]) begin
            mantissa_sum = mantissa_sum >> 1; //shift right
            exp_out = exp_out + 1 ;
        end 

        ////check rounding
//        if (mantissa_sum[24] || (mantissa_sum[23] && mantissa_sum[22:0] != 23'b0 )) begin
//            if(sign_out) begin
//                 mantissa_sum = mantissa_sum - 1;
//            end
//            else begin
//               mantissa_sum = mantissa_sum + 1; 
//            end
//        end

        /*if(~mantissa_sum[23])begin
             exp_out = exp_out - 1;
            mantissa_sum = mantissa_sum << 1;
        end*/
      
        //check normalisation
        while (~ mantissa_sum[23] & (|mantissa_sum) )
            begin
            mantissa_sum = mantissa_sum << 1;
            exp_out = exp_out - 1;
           
            end
        mantissa_out = mantissa_sum[22:0];
         
        //if (zero_exponent) begin
//            if((expA ==0 ) & (expB == 0))begin
//                out = 32'b0;
//                out_valid = 1'b1; 
//            end
//            else if((expA == 0)) begin
//                out = OperandB;
//                out_valid = 1'b1;
//            end
//            else if(expB == 0) begin
//               out = OperandA;
//               out_valid = 1'b1; 
//            end
//        end
         if(NaN) begin
            out = {sign_out,8'b1111_1111, 23'b111_1111_1111_1111_1111_1111};
            out_valid = 1'b1;
        end
        else if(Exception) begin
            out = {sign_out,8'b1111_1111,23'b0};
            out_valid = 1'b1;
        end
        else begin
            out = {sign_out, exp_out, mantissa_out};
            out_valid = 1'b1;
        end
    end
    else begin
        out_valid = 1'b0;
    end
 
end

//assign zero_exponent = ((OperandA[30:23] == 0) || (OperandB[30:23] == 0)) ? 1'b1 : 1'b0;
assign NaN =( ( (OperandA[30:23] == 8'b1111_1111) && (OperandA [22:0] != 23'b0) ) || ( (OperandB[30:23] == 8'b1111_1111) && (OperandB [22:0] != 23'b0) ) ) ? 1 : 0;
assign Exception = ( ( (&OperandA[30:23]) && (OperandA[22:0] == 0) )   || ( (&OperandB[30:23]) && (OperandB[22:0] == 0) ) ) ? 1'b1 : 1'b0;

endmodule 


