module controller (
	input 				clk,
	input   			rst,
	input 		[1:0] 	control,
	input 		[127:0] Datain,
	//////////////////////Kernel memory////////////////////////
	output 	reg			wren_K,
	output	reg [31:0]  wrK_data1,wrK_data2,wrK_data3,wrK_data4,
	output 	reg [5:0] 	K_addr1,K_addr2,K_addr3,K_addr4,
	output  reg			readen_K,
	output 	reg [5:0]	rd_addK,
	///////////////////////Register//////////////////////////
	output  reg			wren_reg,
	output  reg [7:0] 	data_M,data_N,data_S,data_L,data_W,
	output	reg [2:0]   addr_M, addr_N, addr_S, addr_L, addr_W,
	/////////////////////input memory//////////////////////////
	output	reg			wren_in,
	output 	reg [31:0] 	wrin_data1,wrin_data2,wrin_data3,wrin_data4,
	output 	reg [7:0] 	in_addr1,in_addr2,in_addr3,in_addr4,
	output  reg			readen_in,
	output 	reg [7:0]	rd_addin, // pointer_e
	/////////////////////FIFO controller////////////////////////////
	output  reg [7:0]	output_size,
	output reg size_valid ,
	/////////////////////Accumulator///////////////////////////
	//output  reg   	  	Accum_clear,
	output reg [7:0] kernel_size,
	output reg invalid_operation
	);
 
/////////////Size of input, Kernel, Stride Length/////////////
reg [7:0] M,N,S,L,W;
//////////////pointers to save data in correct address when loading////////
reg [7:0] Kadd_pointer;
reg [7:0] inadd_pointer;
//////////////used for calclations//////////////////////////
reg [7:0] R,C,Pointer_E, r ,c;
 
reg start; /// flag to make sure that first address taken is address 0
reg Done;  ///  all addresses are ready for mulplication and accumulation

always @(posedge clk or negedge rst) begin	
	if(~rst) begin
		wren_K <= 0;
		wren_in <= 0;
		wren_reg <= 0;
		Done <= 0;
	 	//Accum_clear <= 1;
	 	Kadd_pointer <= 0;
	 	inadd_pointer <= 0;
	 	R <= 0;
	 	C <= 0;
	 	r <= 0;
	 	c <= 0;
	 	Pointer_E <= 0;
	 	rd_addin <=0 ;
	 	start <= 1;
	 	size_valid <= 1'b0;
	 	addr_M <= 3'd0;
	 	addr_N <= 3'd1;
	 	addr_S <= 3'd2;
	 	addr_L <= 3'd3;
	 	addr_W <= 3'd4;
	end
	else begin
		case (control)
			2'b00: 	begin //load input feature
						M <= Datain[7:0];
						N <= Datain[15:8];
						S <= Datain[23:16];
						L <= Datain[31:24];
						W <= Datain[39:32];
						data_M <= Datain[7:0];
						data_N <= Datain[15:8];
						data_S <= Datain[23:16];
						data_L <= Datain[31:24];
						data_W <= Datain[39:32];
						wren_reg <= 1;
						Kadd_pointer <= 0;
	 					inadd_pointer <= 0;
	 					start <= 1;
	 					output_size <= ((L-M)/S)+1 ;
	 					size_valid <= 1'b1; 
	 					kernel_size <= M; 
	 					Done <= 0;
	 					if ((M != N) || (L != W) || (M > L))
	 					  begin
	 					    invalid_operation <= 1'b1;
	 					    
	 					  end
	 					  else 
	 					    begin
	 					      invalid_operation <= 1'b0;
	 					    end
	 					  
				   	end
			2'b01:	begin // load kernel
						wrK_data1 <= Datain[31:0];
						wrK_data2 <= Datain[63:32];
						wrK_data3 <= Datain[95:64];
						wrK_data4 <= Datain[127:96];
						K_addr1 <= Kadd_pointer;
						K_addr2 <= Kadd_pointer + 1 ;
						K_addr3 <= Kadd_pointer + 2 ;
						K_addr4 <= Kadd_pointer + 3 ;
						Kadd_pointer <= Kadd_pointer + 4;
						//Accum_clear <= 1;
						wren_K <= 1;
						wren_in <= 0;
						wren_reg <= 0;
	 					inadd_pointer <= 0;
	 					start <= 1;
	 					size_valid <= 1'b0;
	 					Done <= 0;
					end
 
			2'b10:	begin // load configuration (loading input image)
						wrin_data1 <= Datain[31:0];
						wrin_data2 <= Datain[63:32];
						wrin_data3 <= Datain[95:64];
						wrin_data4 <= Datain[127:96];
						in_addr1 <= inadd_pointer;
						in_addr2 <= inadd_pointer + 1 ;
						in_addr3 <= inadd_pointer + 2 ;
						in_addr4 <= inadd_pointer + 3 ;
						inadd_pointer <= inadd_pointer + 4;
						Done <=  0;
						
						//Accum_clear <= 1;
						wren_K <= 0;
						wren_in <= 1;
						wren_reg <= 0;
	 					Kadd_pointer <= 0;
	 					start <= 1;
	 					size_valid <= 1'b0;
					end	
 
			2'b11:	begin 
			          wren_K <= 0;
						    wren_in <= 0;
						    wren_reg <= 0;
								if(start) begin // this ensures that first address is address 0 
									rd_addK <= 0;
									rd_addin <= 0;
									readen_in <= 1;
									readen_K <= 1;
									start <= 0;
									size_valid <= 1'b0;
						
								end
								else begin
									if((c == N-1) && (r == M-1) && (~Done)) begin //element of output is done
										c <= 0;
										r <= 0;
										C = C + S; // move the Kernel window to right
										if((C + N) > W && (~Done)) begin //columns finished, check Row increase it by stride or operation finished
											C <= 0;
											R = R + S;	//increment R to move the kernel window down 
											Pointer_E =  0 ; // Reset pointer 
											Pointer_E = W * R;
											rd_addin = Pointer_E;
											rd_addK = 0;
											if((R + M) > L) begin // operation finished (Kernel outside input matrix)
												C = 0 ;
												R = 0;
												//Accum_clear = 1;
												Done = 1;
												readen_in <= 0;
									      readen_K <= 0;
												rd_addin = 0; // reset address, operation finished 
												Pointer_E = 0; //reset pointer, operation finished
												rd_addK = 0; // reset address of Kernel window
											end
										end
										else begin
											if (~Done) begin
												rd_addin <= Pointer_E + S; // update address of input matrix
												Pointer_E <= Pointer_E + S; // update pointer of input matrix
												rd_addK <= 0; // reset address of Kernel window to 0 to get another element of output
											end
										end
									end
									else begin //  element of output is not done yet
										if(((c+1) == N) && (~Done)) begin // check columns of kernel is finished or not
											c <= 0;
											rd_addin <= rd_addin + (L-M+1); // update address of input matrix 
											rd_addK <= rd_addK + 1; // update address of kernel matrix
											if((r+1) == M) begin // check if rows of kernel window is finished or not
												r <= 0;
											end
											else begin //rows of kernel not finished so incresae
												r <= r + 1;
											end
										end
										else begin // columns of kernel not finished so incresae
											if(~Done) begin
												c <= c + 1;
												rd_addin <= rd_addin + 1;
												rd_addK <= rd_addK + 1;
											end
										end
									end
 
								end
 
 
						end
 
						
		endcase
 
 
	end
 
end
 
 
endmodule 


