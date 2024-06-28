`timescale 1ns / 1ps

module Accumulator_tb;

    reg clk;
    reg rst;
    reg [31:0] IN1;
    reg in_valid;
    reg [7:0] kernel_size;
    wire [31:0] Accumulator;
    wire output_valid;

    // Instantiate the Accumulator module
    Accumulator uut (
        .clk(clk), 
        .rst(rst),
        .IN1(IN1),
        .in_valid(in_valid),
        .kernel_size(kernel_size),
        .Accumulator(Accumulator),
        .output_valid(output_valid)
    );

    // Clock generator
    always begin
        #5 clk = ~clk;    // Toggle clock every 5 time units
    end

    // Testbench stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        IN1 = 0;
        in_valid = 0;
        kernel_size = 0;

        #10;
        rst = 1;    
        #10;
        // Apply stimulus to the inputs
        //test case 1
        kernel_size = 8'd2;  //
        #15
        in_valid = 1;
        
        IN1 = 32'h3E99999A;  //0.3
        #10
        IN1 = 32'h3E4CCCCD;  //0.2
        #10
        IN1 = 32'h3DCCCCCD;  //0.1
        #10
        IN1 = 32'hBE4CCCCD;  //-0.2
        #20
        in_valid = 0;
        #10
        
        
        //test case 2
        kernel_size = 8'd3;  //
        #15
        in_valid = 1;
        IN1 = 32'h3E99999A;  //0.3
        #10
        IN1 = 32'h3BF000000;  //-0.5
        #10
        IN1 = 32'h3DCCCCCD;  //0.1
        #10
        IN1 = 32'hBE4CCCCD;  //-0.2
        #10
        IN1 = 32'h3E99999A;  //0.3
        #10
        IN1 = 32'h3E4CCCCD;  //0.2
        #10
        IN1 = 32'hBF000000;  //-0.5
        #10
        IN1 = 32'h3DCCCCCD;  //0.1
        #10
        IN1 = 32'hBE4CCCCD;  //-0.2   //result =-0.4 BF000000
        #20
        in_valid = 0;
        #20 $stop;    // End the simulation
    end

endmodule

