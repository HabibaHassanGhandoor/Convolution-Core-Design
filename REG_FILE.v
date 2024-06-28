module RegFile #(parameter WIDTH = 8, DEPTH = 5, ADDR = 3)
	(
	input 									clk,
	input 									rst,
	input 									wrEn,
	input 									RdEn,
	input 	   [WIDTH-1:0]	WrData1,
	input 	   [WIDTH-1:0]	WrData2,
	input 	   [WIDTH-1:0]	WrData3,
	input 	   [WIDTH-1:0]	WrData4,
	input 	   [WIDTH-1:0]	WrData5,
	input 	   [ADDR-1:0]	Address1,
	input 	   [ADDR-1:0]	Address2,
	input 	   [ADDR-1:0]	Address3,
	input 	   [ADDR-1:0]	Address4,
	input 	   [ADDR-1:0]	Address5,
	output reg		RdData_valid,
	output reg [WIDTH-1:0]	RdData

	); 


integer I ;
  
// register file of 5 registers
reg [WIDTH-1:0] Mem [DEPTH-1:0] ;

always @(posedge clk or negedge rst)
 begin
	if(~rst) 
	begin
	RdData_valid = 1'b0;
	for (I=0 ; I < DEPTH ; I = I +1)
        begin
              Mem[I] <= 'b0;                
        end
   	end
   	else if(wrEn)
   	begin
   		Mem[Address1] <= WrData1;
   		Mem[Address2] <= WrData2;
   		Mem[Address3] <= WrData3;
   		Mem[Address4] <= WrData4;
   		Mem[Address5] <= WrData5;

   		 RdData_valid = 1'b0;			
   	end	
   	else
   	begin
   	 if(RdEn)
   	  begin
   		RdData <= Mem[Address1]; //in case of read address will be on address1 bus
   		RdData_valid = 1'b1;		
   	  end
   	end 
 end

endmodule 


