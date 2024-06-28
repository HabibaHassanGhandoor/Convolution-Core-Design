`timescale 1ns / 1ps

module FIFO(
input clk,rst, write_en, read_en,
input [31:0] data_in,
output reg [31:0] data_out,
output reg [7:0] counter, //keeps track on where we stand now in the circular quque (FIFO) of depth = 32
output reg empty, full ); // we cannot read from an empty FIFO or write in a full one

parameter width = 32; // The length of the data (word)
parameter depth = 256; // The number of locations in the FIFO bec. 32 x 32 = 1024 = 1KB
reg read_address, write_address;
reg [width-1:0] memory [0:depth-1];

//------------------------------------Status Determination------------------------------------------//
always @(counter) begin //when counter value changes check the status
full = (counter == 32) ? 1'b1 : 1'b0;
empty = (counter == 0) ? 1'b1 : 1'b0;
end

//------------------------------------Counter Calculation-------------------------------------------//
always @(posedge clk or negedge rst) 
begin
    if (~rst)
        counter <= 0;
    else if (~full && write_en)
        counter <= counter + 1; // writing & buffer not full so counter incremented
    else if (~empty && read_en)
        counter <= counter - 1; // reading & buffer not empty so counter decremented
    else 
        counter <= counter;  // If neither reading nor writing then counter preserves state
end
//------------------------------------Address Pointers-------------------------------------------//     
always @(posedge clk or negedge rst)
begin
    if (~rst) begin
        read_address <= 0; //Read pointer holda no location
        write_address <= 0; //write pointer holda no location
    end
    else begin
        if (~full && write_en)
            write_address <= write_address + 1; // After writing in required address increment address pointer 
        else
            write_address <= write_address; //else preserve pointer state
        if (~empty && read_en)
            read_address <= read_address + 1; // After reading from required address increment address pointer 
        else
            read_address <= read_address; //else preserve pointer state
        end
end
//------------------------------------Read Condition-------------------------------------------//     
always @(posedge clk or negedge rst) 
begin
    if (~rst)
        data_out <= 0;
    else if (~empty && read_en) //Read mode enabled & FIFO not empty
        data_out <= memory[read_address]; //Read the data addressed by the read pointer 
    else
    data_out <= data_out; //Keep current state
end
//------------------------------------Write Condition-------------------------------------------// 
always @(posedge clk) //No need to check reset when writing 
begin
    if (~full && write_en) // if FIFO write mode is ready
        memory[write_address] <= data_in; // write input data where write pointer (address) points
    else
        memory[write_address] <= memory[write_address]; //Saved  value preserved
end
endmodule


