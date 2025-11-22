`timescale 1ns/1ps

module tb;
    // Parameters
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam MEM_SIZE_BYTES      = 64;

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
        .MEM_SIZE_BYTES(MEM_SIZE_BYTES)
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
    
    function  void print(string tag, logic [ADDR_WIDTH-1:0] addr, logic [DATA_WIDTH-1:0] data, logic [(DATA_WIDTH/8)-1:0] wstrb =0 );
        $display("Time = %t | Tag = %s | ADDR = %h | DATA = %h | WSTRB = %b", $time, tag, addr, data, wstrb);
    endfunction
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

        print("Write",addr, data, wstrb);
    end
    endtask
     // AXI-Lite Read Task
    task axi_read(input [31:0] addr, output [31:0] data_out);
    begin
        @(posedge clk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1;
        //$display("first");

        wait(!s_axi_arready);
        //$display("CS = %0d | NS = %s", dut.CS.name(), dut.NS.name());
        //$display("Second");
        @(posedge clk);
        s_axi_arvalid <= 0;
        // wait for RVALID
        s_axi_rready <= 1;
        wait(s_axi_rvalid);
        //$display("Third");
        data_out = s_axi_rdata;
        @(posedge clk);
        s_axi_rready <= 0;
        
        print("Read", addr, data_out);
    end
    endtask
    int addr_list [4] = '{32'h0000_0000,
                      32'h0000_0004,
                      32'h0000_0008,
                      32'h0000_0012};

    int wstrb_list [4] = '{4'b0001,
                      4'b0010,
                      4'b0011,
                      4'b0100};
    // Test Sequence
    initial begin
        integer i;
        reg [31:0] rdata;
        @(posedge rstn);
        #20;

        for (int i = 0; i < 4; i++) begin
            axi_write(addr_list[i], 32'hAAAAAAAA, wstrb_list[i]);
            axi_read(addr_list[i], rdata);
        end
        $display("Test completed.");
        #50;
        $stop;
    end

    always @(posedge clk) begin
        $display("Time= %0t | CS=%s | NS=%s ", $time, dut.CS.name(),dut.NS.name());
    end

endmodule
