module RegFile_tb;

    parameter WIDTH = 8, DEPTH = 5, ADDR = 3;

    // Signals
    reg clk;
    reg rst;
    reg wrEn;
    reg RdEn;
    reg [WIDTH-1:0] WrData [4:0]; // Array for WrData
    reg [ADDR-1:0] Address1, Address2, Address3, Address4, Address5;
    wire [WIDTH-1:0] RdData;
    wire RdData_valid;
    integer pass_count = 0;    
    integer fail_count = 0; 
    integer i ;

    initial begin
        clk = 0;
        rst = 1;
        wrEn = 0;
        RdEn = 0;
        WrData[0] = 0;
        WrData[1] = 0;
        WrData[2] = 0;
        WrData[3] = 0;
        WrData[4] = 0;
        Address1 = 0;
        Address2 = 1;
        Address3 = 2;
        Address4 = 3;
        Address5 = 4;

        // Reset
        #10 rst = 0;
        #20 rst = 1;

        repeat(20) begin
          // Write to and read from the registers
            // Write
            wrEn = 1;
            
            for (i = 0; i < DEPTH; i = i + 1) begin
                WrData[i] = $random;
            end
            #10;

            // Read
            wrEn = 0;
            #20;

            for (i = 0; i < DEPTH; i = i + 1) begin
                RdEn = 1;
                Address1 = i;
                #10;
                if (RdData !== WrData[i]) begin
                    $display("Test failed at address %0d: WrData = %0d, RdData = %0d, time = %d", i, WrData[i], RdData, $time);
                    fail_count = fail_count + 1;
                end
                else begin
                    pass_count = pass_count + 1;
                end

                RdEn = 0;
                #10;
            end
            Address1 = 0;
            #40;  
        end
        

            $display("simulation finished");
            $display("Passed Tests = %d", pass_count);
            $display("Failed Tests = %d", fail_count);
            $stop;
        end

    // Clock generator
    always begin
        #5 clk = ~clk;
    end

    // DUT instantiation
    RegFile #(WIDTH, DEPTH, ADDR) dut (
        .clk(clk),
        .rst(rst),
        .wrEn(wrEn),
        .RdEn(RdEn),
        .WrData1(WrData[0]),
        .WrData2(WrData[1]),
        .WrData3(WrData[2]),
        .WrData4(WrData[3]),
        .WrData5(WrData[4]),
        .Address1(Address1),
        .Address2(Address2),
        .Address3(Address3),
        .Address4(Address4),
        .Address5(Address5),
        .RdData_valid(RdData_valid),
        .RdData(RdData)
    );

endmodule
