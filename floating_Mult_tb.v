module floating_Mult_tb;
    reg 			 clk;
    reg 			 rst;
    reg 	[31:0] 	 OperandA;
    reg 	[31:0] 	 OperandB;
    reg 	   		 in_valid;
    wire			 Exception;
    wire 			 NaN;
    wire			 zero_exponent;
    wire 		     out_valid;
    wire 	[31:0]	 out;

	localparam clk_period = 10;
	localparam BIAS = 127;

    //store random values
   reg [31:0] OperandA_rand;
   reg [31:0] OperandB_rand;
   // expected outputs
   reg [31:0] expected_out;
   reg expected_valid_out;

   reg sign_expected;
   reg [22:0] Mantissa_expected;
   reg [7:0] exponent_expected;
   reg [47:0] product;
   reg Exception_expected,zero_exponent_expected, NaN_expected;
   reg [23:0] Mantissa1,Mantissa2;
   reg normalize;

   //counters to count pass and fail
   integer pass_count = 0;
   integer fail_count = 0;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 0;
        OperandA = 0;
        OperandB = 0;
        in_valid = 0;
        //testing reset
        reset();
        #clk_period;
        repeat (100) begin
        mult();
        #40;

        end
        #100;
        test_Exception_expected();
        #100;
        test_zero_exponent_exponent();
        #100;
        negative();
        #100;
        positive_negative();
        #100;
        test_NAN();
        #100;
        test_1zero_exponent_Mantissa();
        #100;
        test_2zero_exponent_Mantissa();
        
        $display("simulation finished");
        $display("Passed Tests = %d", pass_count);
        $display("Failed Tests = %d", fail_count);
        $stop;
    end

    //for testing reset
    task reset();
    	begin
    	rst = 1;
    	#clk_period rst = 0;
    	#clk_period rst = 1;
    	#5 check_output();
    end
    endtask

    task mult();
    	begin
    	OperandA = $random;
    	OperandA_rand = OperandA;
        OperandB = $random;
        OperandB_rand = OperandB;
        in_valid = 1;
        #5;
        check_output();
        #5 in_valid = 0;
        #20;
    	end
    endtask

    task check_output();
    	begin
    	golden_model(OperandA_rand, OperandB_rand);
    	if ((expected_out == out) && (expected_valid_out == out_valid) && (Exception == Exception_expected))  begin
    		pass_count = pass_count + 1;
    	end
    	else begin
    		fail_count = fail_count +1;
    		$display("Test Failed: expected output = %0x , output = %0x, expected_valid_out = %b ,out_valid = %b,Exception = %b , Exception_expected = %b,time = %t", expected_out, out, expected_valid_out, out_valid, Exception, Exception_expected,$time );
    	end
    end
    endtask

    task golden_model(input [31:0] OperandA, input [31:0] OperandB);
    	begin
    	if(~rst) begin
    		expected_out = 0;
    		expected_valid_out = 0;
    		Exception_expected = 0;
    	end
    	else if (in_valid) begin
    		sign_expected = OperandA[31] ^ OperandB[31];
    		Exception_expected =( ( (&OperandA[30:23]) && (OperandA[22:0] == 0) )   || ( (&OperandB[30:23]) && (OperandB[22:0] == 0) ) ) ? 1'b1 : 1'b0;// infinity number
    		NaN_expected =( ( (OperandA[30:23] == 8'b1111_1111) && (OperandA [22:0] != 23'b0) ) || ( (OperandB[30:23] == 8'b1111_1111) && (OperandB [22:0] != 23'b0) ) ) ? 1 : 0; 
    		//set implicit bit
    		Mantissa1 = (|OperandA[30:23]) ? {1'b1,OperandA[22:0]} : {1'b0,OperandA[22:0]};
    		Mantissa2 = (|OperandB[30:23]) ? {1'b1,OperandB[22:0]} : {1'b0,OperandB[22:0]};
    		product = Mantissa1 * Mantissa2;
    		normalize = product[47];
    		zero_exponent_expected = ((OperandA[30:23] == 0) | (OperandB[30:23] == 0)) ? 1'b1 : 1'b0;
    		if(~normalize & ~zero_exponent) begin
      			product = product << 1 ;
      			Mantissa_expected = product[46:24] + product[23] ;
      			normalize = product[47];
      			exponent_expected = (OperandA[30:23] + OperandB[30:23] - BIAS);
    		end
  			else begin
  				Mantissa_expected = product [46:24];
  				exponent_expected = (OperandA[30:23] + OperandB[30:23] - BIAS) + normalize;
  			end

  			if (zero_exponent_expected) begin
                expected_out = 32'b0;
                expected_valid_out = 1'b1;
            end
            else if(NaN) begin
                expected_out = {sign_expected,8'b1111_1111, 23'b111_1111_1111_1111_1111_1111};
                expected_valid_out = 1'b1;
            end
            else if(Exception) begin
                expected_out = {sign_expected,8'b1111_1111,23'b0};
                expected_valid_out= 1'b1;
            end
            else if (normalize) begin
                expected_out = {sign_expected, exponent_expected, Mantissa_expected};
                expected_valid_out = 1'b1;
            end
    	end
    	else begin
    		expected_out = 0;
    		expected_valid_out = 0;
    		Exception_expected = 0;
    	end
    end
    endtask

    //Directive Testcases
    task test_Exception_expected();
    	begin
    		OperandA = 32'hffff;
    		OperandB = 32'h8ca2;
    		OperandA_rand = OperandA;
			OperandB_rand = OperandB;
    		in_valid = 1;
    		#5;
    		check_output();
    		#5 in_valid = 0;
    	end
    endtask

    task test_zero_exponent_exponent();
    	begin
    		OperandA = 32'b00000000001110100100101011010011;
    		OperandB = 32'b01000000000100001010001111010111;
    		OperandA_rand = OperandA;
			OperandB_rand = OperandB;
    		in_valid = 1;
    		#5;
    		check_output();
    		#5 in_valid = 0;
    	end
    endtask

    task test_2zero_exponent_Mantissa();
    	begin
    		OperandA = 32'b01000000100000000000000000000000; //4.0
    		OperandB = 32'b01000001100000000000000000000000; //16.0
    		OperandA_rand = OperandA;
			OperandB_rand = OperandB;
    		in_valid = 1;
    		#5;
    		check_output();
    		#5 in_valid = 0;
    	end
    endtask

    task test_1zero_exponent_Mantissa();
    	begin
    		OperandA = 32'b01000000100000000000000000000000; //4.0
    		OperandB = 32'b01000001100000100000110100011011; //16.254
    		OperandA_rand = OperandA;
			OperandB_rand = OperandB;
    		in_valid = 1;
    		#5;
    		check_output();
    		#5 in_valid = 0;
    	end
    endtask

    //multiply 2 negative numbers
    task negative();
    	begin
    		OperandA = 32'b10111111100110011001100110011010; // -1.2
    		OperandB = 32'b11000000000100110011001100110011; //-2.3
    		OperandA_rand = OperandA;
			OperandB_rand = OperandB;
    		in_valid = 1;
    		#5;
    		check_output();
    		#5 in_valid = 0;
    	end
    endtask

    //multiply 2 negative numbers
    task positive_negative();
    	begin
    		OperandA = 32'b11000011111110100101001110110110; // -500.654
    		OperandB = 32'b01000011100001000111110101110001; //264.98
    		OperandA_rand = OperandA;
			OperandB_rand = OperandB;
    		in_valid = 1;
    		#5;
    		check_output();
    		#5 in_valid = 0;
    	end
    endtask

    //test NAN
    task test_NAN();
    	begin
    		OperandA = 32'hFFFFFFFF; // NaN
    		OperandB = 32'b01000011100001000111110101110001; //264.98
    		OperandA_rand = OperandA;
			OperandB_rand = OperandB;
    		in_valid = 1;
    		#5;
    		check_output();
    		#5 in_valid = 0;
    	end
    endtask


    // clock generation
    always #5 clk = ~clk;

    // Instantiate the Unit Under Test (UUT)
    floating_Mult uut (
        .clk(clk), 
        .rst(rst), 
        .OperandA(OperandA), 
        .OperandB(OperandB), 
        .in_valid(in_valid),
        .zero_exponent(zero_exponent),
        .Exception(Exception),
        .NaN(NaN),
        .out_valid(out_valid), 
        .out(out)
    );

endmodule

