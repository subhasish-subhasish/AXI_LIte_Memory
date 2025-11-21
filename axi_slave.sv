`timescale 1ns/1ps

module axilite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 128          // number of 32-bit words (addressed by word)
)(
    //global signal
    input  wire                    s_axi_aclk,
    input  wire                    s_axi_aresetn,

    // Write address channel
    input  wire                    s_axi_awvalid,
    output logic                    s_axi_awready,
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,

    // Write data channel
    input  wire                    s_axi_wvalid,
    output logic                    s_axi_wready,
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,

    // Write response channel
    output logic                   s_axi_bvalid,
    input  wire                    s_axi_bready,
    output logic [1:0]             s_axi_bresp,

    // Read address channel
    input  wire                    s_axi_arvalid,
    output logic                   s_axi_arready,
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,

    // Read data channel
    output logic                   s_axi_rvalid,
    input  wire                    s_axi_rready,
    output logic [DATA_WIDTH-1:0]  s_axi_rdata,
    output logic [1:0]             s_axi_rresp
);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_WRITE_ADDR,
        ST_WRITE_DATA,
        ST_WRITE_RESP,
        ST_READ_ADDR,
        ST_READ_DATA
    } state_t;

    state_t CS, NS;

    // Simple memory: word-addressed. Use lower bits as byte offset.
    localparam ADDR_WORD_OFFSET = $clog2(DATA_WIDTH/8); // typically 2 for 32-bit
    localparam ADDR_WORD_WIDTH  = $clog2(DEPTH);

    // internal registers to hold captured address/data
    logic [ADDR_WIDTH-1:0] awaddr_reg;
    logic [ADDR_WIDTH-1:0] araddr_reg;
    logic [DATA_WIDTH-1:0] wdata_reg;
    logic [DATA_WIDTH-1:0] rdata_reg;
    logic [(DATA_WIDTH/8)-1:0] wstrb_reg;

    // small synchronous memory
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // flags to indicate we've captured AW or W or AR
    logic aw_captured;
    logic w_captured;
    logic ar_captured;

    // response default
    localparam [1:0] RESP_OKAY = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [1:0] RESP_DECERR = 2'b11;

    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            CS <= ST_IDLE;

             // clear handshake outputs
            //s_axi_awready <= 1'b0;
            //s_axi_wready  <= 1'b0;
            //s_axi_bvalid  <= 1'b0;
            //s_axi_bresp   <= RESP_OKAY;
            //s_axi_arready <= 1'b0;
            //s_axi_rvalid  <= 1'b0;
            //s_axi_rdata   <= '0;
            //s_axi_rresp   <= RESP_OKAY;

            // clear internals
            // awaddr_reg <= '0;
            // araddr_reg <= '0;
            // wdata_reg  <= '0;
            // rdata_reg  <= '0;
            // wstrb_reg <=  '0;

            aw_captured <= 1'b0;
            w_captured  <= 1'b0;
            ar_captured <= 1'b0;

            // initialize memory to zero (synthesis tools will optimize)
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] <= '0;
            end
        end else begin
            CS <= NS;

            if(s_axi_awvalid && s_axi_awready)begin
                aw_captured <= 1'b1;
                awaddr_reg  <= s_axi_awaddr;
            end else if(CS == ST_WRITE_RESP && s_axi_bready && s_axi_bvalid)begin
                aw_captured <= 1'b0;
            end

            if(s_axi_wvalid && s_axi_wready)begin
                w_captured <= 1'b1;
                wdata_reg <= s_axi_wdata;
                wstrb_reg <= s_axi_wstrb;
            end else if(CS == ST_WRITE_RESP && s_axi_bready && s_axi_bvalid)begin
                w_captured <= 1'b0;
            end 

            if (s_axi_arvalid && s_axi_arready) begin
                ar_captured <= 1'b1;
                araddr_reg  <= s_axi_araddr;
            end else if (CS == ST_READ_DATA && s_axi_rready && s_axi_rvalid) begin
                ar_captured <= 1'b0;
            end
        end
    end

    //next state logic
    always_comb begin
        // default next state
        NS = CS;
        case(CS)
            ST_IDLE: begin
                if(s_axi_awvalid && !aw_captured )
                    NS = ST_WRITE_ADDR;
                else if(s_axi_arvalid && !ar_captured)
                    NS = ST_READ_ADDR;
                else
                    NS = ST_IDLE;
            end
            ST_WRITE_ADDR:begin
                if(s_axi_wvalid && !w_captured )
                    NS = ST_WRITE_DATA;
                else if(w_captured)
                    NS = ST_WRITE_DATA;
                else 
                    NS = ST_WRITE_ADDR;
            end
            ST_WRITE_DATA:begin
                NS = ST_WRITE_RESP;
            end
            ST_WRITE_RESP:begin 
                if (s_axi_bvalid && s_axi_bready) begin
                    NS = ST_IDLE;
                end else begin
                    NS = ST_WRITE_RESP;
                end
            end
            ST_READ_ADDR:begin
                NS = ST_READ_DATA;
            end
            ST_READ_DATA:begin
                if (s_axi_rvalid && s_axi_rready) begin
                    NS = ST_IDLE;
                end else begin
                    NS = ST_READ_DATA;
                end
            end
            default: NS = ST_IDLE;
        endcase
    end


    //output and protocall behavior
    always_comb begin
        s_axi_awready = 1'b0;
        s_axi_wready  = 1'b0;
        s_axi_bvalid  = 1'b0;
        s_axi_bresp   = RESP_OKAY;
        s_axi_arready = 1'b0;
        s_axi_rvalid  = 1'b0;
        s_axi_rdata   = '0;
        s_axi_rresp   = RESP_OKAY;

        // Default computed rdata_reg
        rdata_reg = '0;

        case(NS)
            ST_IDLE: begin
                // ready to accept AW/W/AR when idle (but if already captured, rely on flags)
                s_axi_awready = ~aw_captured;
                s_axi_wready  = ~w_captured;
                s_axi_arready = ~ar_captured;
            end
            ST_WRITE_ADDR:begin
                // assert awready until we capture AW (captured in seq block)
                s_axi_awready = ~aw_captured;
                s_axi_wready  = ~w_captured; // also accept W if ready
            end
            ST_WRITE_DATA:begin
                s_axi_wready = 1'b1;
            end
            ST_WRITE_RESP:begin
                s_axi_bvalid = 1'b1;
                s_axi_bresp  = RESP_OKAY;
            end
            ST_READ_ADDR:begin
                s_axi_arready = ~ar_captured;
            end
            ST_READ_DATA:begin
                s_axi_rvalid = 1'b1;
                if ( (araddr_reg >> ADDR_WORD_OFFSET) < DEPTH ) begin
                    rdata_reg = mem[ araddr_reg >> ADDR_WORD_OFFSET ];
                    s_axi_rresp = RESP_OKAY;
                end else begin
                    rdata_reg = '0;
                    s_axi_rresp = RESP_DECERR;
                end
                s_axi_rdata = rdata_reg;
            end
        endcase
    end





    /////////////////////////////////////////////
     always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            // already initialized above
        end else begin
            if ( (aw_captured || (s_axi_awvalid && s_axi_awready) ) && ( w_captured || (s_axi_wvalid && s_axi_wready))) begin
                logic [ADDR_WORD_WIDTH-1:0] windex; //write index
                windex = ( (aw_captured ? awaddr_reg : s_axi_awaddr ) >> ADDR_WORD_OFFSET );
                if (windex < DEPTH) begin                   
                    for (int i = 0; i < (DATA_WIDTH/8); i++) begin
                        logic wstrb_bit;
                        logic [DATA_WIDTH-1:0] tmp; 
                        logic [7:0] src_byte;
                        wstrb_bit = w_captured ? wstrb_reg[i] : s_axi_wstrb[i];
                        if (wstrb_bit) begin                         
                            src_byte = w_captured ? wdata_reg[(i*8)+:8]:s_axi_wdata[(i*8)+:8];
                            tmp = mem[windex];
                            tmp[(i*8)+:8] = src_byte;
                            mem[windex] <= tmp;
                        end
                    end
                end
            end
        end
     end
endmodule