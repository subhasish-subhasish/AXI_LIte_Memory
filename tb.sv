`timescale 1ns/1ps

module tb_axilite_slave;
    // Parameters
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam DEPTH      = 128;

    // DUT signals
    reg                     clk;
    reg                     rstn;

    reg                     s_axi_awvalid;
    wire                    s_axi_awready;
    reg  [ADDR_WIDTH-1:0]   s_axi_awaddr;

    reg                     s_axi_wvalid;
    wire                    s_axi_wready;
    reg  [DATA_WIDTH-1:0]   s_axi_wdata;
    reg  [DATA_WIDTH/8-1:0] s_axi_wstrb;

    wire                    s_axi_bvalid;
    reg                     s_axi_bready;
    wire [1:0]              s_axi_bresp;

    reg                     s_axi_arvalid;
    wire                    s_axi_arready;
    reg  [ADDR_WIDTH-1:0]   s_axi_araddr;

    wire                    s_axi_rvalid;
    reg                     s_axi_rready;
    wire [DATA_WIDTH-1:0]   s_axi_rdata;
    wire [1:0]              s_axi_rresp;


    axilite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .s_axi_aclk   (clk),
        .s_axi_aresetn(rstn),

        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_awaddr (s_axi_awaddr),

        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_wdata (s_axi_wdata),
        .s_axi_wstrb (s_axi_wstrb),

        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_bresp (s_axi_bresp),

        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_araddr (s_axi_araddr),

        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .s_axi_rdata (s_axi_rdata),
        .s_axi_rresp (s_axi_rresp)
    );
    
    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz
    end
    //rst
    initial begin
        rstn = 0;
        s_axi_awvalid = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        #50;
        rstn = 1;
    end

    // AXI-Lite Write Task (single beat)
    task axi_write(input [31:0] addr, input [31:0] data, input [3:0] wstrb);
    begin
        @(posedge clk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1;
        s_axi_wdata   <= data;
        s_axi_wstrb   <= wstrb;
        s_axi_wvalid  <= 1;

        // wait for AWREADY & WREADY
        wait(s_axi_awready && s_axi_wready);
        @(posedge clk);
        s_axi_awvalid <= 0;
        s_axi_wvalid  <= 0;

        // wait for BVALID
        s_axi_bready <= 1;
        wait(s_axi_bvalid);
        @(posedge clk);
        s_axi_bready <= 0;

        $display("[WRITE] ADDR=%h DATA=%h WSTRB=%b", addr, data, wstrb);
    end
    endtask
     // AXI-Lite Read Task
    task axi_read(input [31:0] addr, output [31:0] data_out);
    begin
        @(posedge clk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1;

        wait(s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 0;

        // wait for RVALID
        s_axi_rready <= 1;
        wait(s_axi_rvalid);
        data_out = s_axi_rdata;
        @(posedge clk);
        s_axi_rready <= 0;

        $display("[READ ] ADDR=%h DATA=%h", addr, data_out);
    end
    endtask

    // Test Sequence
    initial begin
        integer i;
        reg [31:0] rdata;
        @(posedge rstn);
        #20;
        //---------------------------------------
        // 1. FULL WORD WRITE
        //---------------------------------------
        axi_write(32'h0000_0004, 32'hAABBCCDD, 4'b1111);
        //---------------------------------------
        // 2. READ BACK
        //---------------------------------------
        axi_read(32'h0000_0004, rdata);
        //---------------------------------------
        // 3. PARTIAL BYTE WRITE
        //---------------------------------------
        axi_write(32'h0000_0004, 32'hAAAAAA11, 4'b0001); // write only lowest byte
        //---------------------------------------
        // 4. READ BACK
        //---------------------------------------
        axi_read(32'h0000_0004, rdata);

        //---------------------------------------
        // 5. RANDOM MULTIPLE WRITES/READS
        //---------------------------------------
        for (i=0; i<5; i=i+1) begin
            axi_write(i*4, 32'h1000 + i, 4'b1111);
            axi_read(i*4, rdata);
        end

        $display("Test completed.");
        #50;
        $stop;
    end

endmodule