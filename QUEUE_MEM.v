`timescale 1ns / 1ps

module Queue_Memory
# (parameter address_width = 5, data_width = 32, depth = 256)
//word size is 32 bits. Memory size is 1kB (1024 bits) so 32x32=1024
(
input clk,rd_ena,rd_enb,wr_ena,wr_enb,
input [address_width-1:0] addressa0,addressa1,addressa2,addressa3,
input [address_width-1:0] addressb0,addressb1,addressb2,addressb3,
input [address_width-1:0] address_reada,address_readb, // a signal to choose which address to get to the output (be read)
input [data_width-1:0] dataina0,dataina1,dataina2,dataina3,
input [data_width-1:0] datainb0,datainb1,datainb2,datainb3,
output reg [data_width-1:0] dataouta, dataoutb,
output reg out_valid
    );
    reg [data_width-1:0] memory [0:depth-1];
    
    //---------------------port A----------------------------//
    always@(posedge clk)
    begin
    if(wr_ena) begin //  write mode on port A
    memory[addressa0] <= dataina0;
    memory[addressa1] <= dataina1;
    memory[addressa2] <= dataina2;
    memory[addressa3] <= dataina3;
   
    end
    else if (rd_ena) begin
    dataouta <= memory[address_reada]; //read mode on port A 
    
    end
    else
    dataouta <= dataouta;
  
    end
    //---------------------port B----------------------------//
    always@(posedge clk)
    begin
    if(wr_enb) begin // write mode on port B
    memory[addressb0] <= datainb0;
    memory[addressb1] <= datainb1;
    memory[addressb2] <= datainb2;
    memory[addressb3] <= datainb3;
    out_valid <= 0;
    end
    else if (rd_enb) begin
    dataoutb <= memory[address_readb]; //read mode on port B 
    out_valid <= 1;
    end
    else  begin
    dataoutb <= dataoutb;
    out_valid <= 0;
    end
    end
endmodule

