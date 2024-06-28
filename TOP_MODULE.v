module top ( input clk , rst,
            input [127:0] Datain,
            input [1:0] control,
            output Valid ,Done,
            output [127:0] Dataout,
            output invalid_operation
            );
            
            
//kernel signals
wire [5:0] k_add0 , k_add1 , k_add2 , k_add3;
wire [31:0] k_data0 , k_data1 , k_data2 , k_data3;
wire wr_en_k , rd_en_k ;
wire [5:0] rd_add_k ;
wire [31:0] rd_data_k;
wire out_valid_k;
// input memory signals
wire [7:0] in_add0 , in_add1 , in_add2 , in_add3;
wire [31:0] in_data0 , in_data1 , in_data2 , in_data3;
wire wr_en_in , rd_en_in ;
wire [7:0] rd_add_in ;
wire [31:0] rd_data_in;
wire out_valid_in;
//reg_file signals
wire [7:0] reg_data0 , reg_data1 ,reg_data2 ,reg_data3 , reg_data4;
wire [2:0] reg_add0 , reg_add1 , reg_add2 , reg_add3 , reg_add4;
wire reg_wr_en , reg_rd_en;
//signals btw multiplier & accumulator
wire acc_en;
wire [31:0] mult_result;
wire clear_acc;
//signals btw fifo and accumulator
wire wr_en_fifo ;
wire [31:0] data_in_fifo ;
//signals btw fifo & fifo_controller
wire [31:0] data_out_fifo;
wire rd_en_fifo;
wire fifo_empty;
wire size_valid;
wire [7:0] output_size;
//signals btw controller & accumulator
wire [7:0]  kernel_size;


//multiplier instantiation
floating_Mult multiplier(
    .clk(clk), 
    .rst(rst),
    .OperandA(rd_data_in),             //from input memory
    .OperandB(rd_data_k),              //from kernel memory
    .in_valid(out_valid_k),
    .zero_exponent(), 
    .Exception(), 
    .NaN(), 
    .out_valid(acc_en),
    .out(mult_result)
);  

//accumulator instantiation
Accumulator accumulator(
    .clk(clk), 
    .rst(rst),
    .IN1(mult_result),
    //.clear(clear_acc),
    .in_valid(acc_en),
    .Accumulator(data_in_fifo),
    .output_valid(wr_en_fifo),
    .kernel_size(kernel_size)
    );
    
    
//FIFO instantiation
FIFO  #( (32) , (256))fifo(
.clk(clk),
.rst(rst),
.write_en(wr_en_fifo),
.read_en(rd_en_fifo),
.data_in(data_in_fifo),
.data_out(data_out_fifo),
.counter(),
.empty(fifo_empty),
.full()
);

//fifo controller instantiation
fifo_controller f_controller
 (.clk(clk),
 .rst(rst),
 .fifo_empty(fifo_empty),
 .output_size(output_size),
 .size_valid(size_valid),
 .fifo_data(data_out_fifo),
 .Dataout(Dataout),
 .valid(Valid),
 .done(Done),
 .fifo_en(rd_en_fifo)
 );


//RegFile instantiation
RegFile  #(8,5,3)
	regfile(
	.clk(clk),
	.rst(rst),
	.wrEn(reg_wr_en),
	.RdEn(reg_rd_en),
	.WrData1(reg_data0),
	.WrData2(reg_data1),
	.WrData3(reg_data2),
	.WrData4(reg_data3),
	.WrData5(reg_data4),
	.Address1(reg_add0),
	.Address2(reg_add1),
	.Address3(reg_add2),
	.Address4(reg_add3),
	.Address5(reg_add4),
	.RdData_valid(),
	.RdData()

	); 
	
	//controller instantiation
	controller c(
	.clk(clk),
	.rst(rst),
	.control(control),
	.Datain(Datain),
	//////////////////////Kernel memory////////////////////////
	.wren_K(wr_en_k),
	.wrK_data1(k_data0),
	.wrK_data2(k_data1),
	.wrK_data3(k_data2),
	.wrK_data4(k_data3),
	.K_addr1(k_add0),
	.K_addr2(k_add1),
	.K_addr3(k_add2),
	.K_addr4(k_add3),
	.readen_K(rd_en_k),
	.rd_addK(rd_add_k),
	///////////////////////register//////////////////////////
	.wren_reg(reg_wr_en),
	.data_M(reg_data0),
	.data_N(reg_data1),
	.data_S(reg_data2),
	.data_L(reg_data3),
	.data_W(reg_data4),
	.addr_M(reg_add0),
	.addr_N(reg_add1),
	.addr_S(reg_add2),
	.addr_L(reg_add3),
	.addr_W(reg_add4),
	/////////////////////input memory//////////////////////////
	.wren_in(wr_en_in),
	.wrin_data1(in_data0),
	.wrin_data2(in_data1),
	.wrin_data3(in_data2),
	.wrin_data4(in_data3),
	.in_addr1(in_add0),
	.in_addr2(in_add1),
	.in_addr3(in_add2),
	.in_addr4(in_add3),
	.readen_in(rd_en_in),
	.rd_addin(rd_add_in), // pointer_e
	/////////////////////FIFO controller////////////////////////////
	.output_size(output_size),
	.size_valid(size_valid) ,
	/////////////////////Accumulator///////////////////////////
	//.Accum_clear(clear_acc),
	.kernel_size(kernel_size),
	.invalid_operation(invalid_operation)
	);
	
	//memory instantiation (input memory)
	Queue_Memory 
# (8,32,256)
input_memory(
.clk(clk),
.rd_ena(),
.rd_enb(rd_en_in),
.wr_ena(wr_en_in),
.wr_enb(),
.addressa0(in_add0),
.addressa1(in_add1),
.addressa2(in_add2),
.addressa3(in_add3),
.addressb0(),
.addressb1(),
.addressb2(),
.addressb3(),
.address_reada(),
.address_readb(rd_add_in), // a signal to choose which address to get to the output (be read)
.dataina0(in_data0),
.dataina1(in_data1),
.dataina2(in_data2),
.dataina3(in_data3),
.datainb0(),
.datainb1(),
.datainb2(),
.datainb3(),
.dataouta(),
.dataoutb(rd_data_in),
.out_valid(out_valid_in)
    );
    
    
//memory instantiation (kernel memory)
	Queue_Memory 
# (6,32,64)
kernel_memory(
.clk(clk),
.rd_ena(),
.rd_enb(rd_en_k),
.wr_ena(wr_en_k),
.wr_enb(),
.addressa0(k_add0),
.addressa1(k_add1),
.addressa2(k_add2),
.addressa3(k_add3),
.addressb0(),
.addressb1(),
.addressb2(),
.addressb3(),
.address_reada(),
.address_readb(rd_add_k), // a signal to choose which address to get to the output (be read)
.dataina0(k_data0),
.dataina1(k_data1),
.dataina2(k_data2),
.dataina3(k_data3),
.datainb0(),
.datainb1(),
.datainb2(),
.datainb3(),
.dataouta(),
.dataoutb(rd_data_k),
.out_valid(out_valid_k)
    );


endmodule

