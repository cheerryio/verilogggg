// word:    |                           2                          |           1           |        0        |
// byte:    | 11..10 |          09          |          08          |  07..06   |  05..04   | 03..02 | 01..00 |
// bit:     | 31..16 | 15..10 |  09  |  08  | 07..02 |  01  |  00  |  31..16   |  15..00   | 31..16 | 15..00 |
// write:   |    X   |    X   | rxim | txim |    X   |   X  |   X  | rx irq th | tx irq th |    X   | tx cmd |
// read:    |    X   |    X   | rxim | txim |    X   | rxis | txis | rx fifo w | tx fifo w | rx dat |    X   |
module iic_master
#(
    parameter real CLK_FREQ = 100e6,
    // max time: 1023 / CLK_FREQ
    // T_SSU: Setup time for repeat START
    // T_SSU + T_PH = MIN BUS IDLE
    parameter real T_SSU  = 0.6e-6,
    parameter real T_SH   = 0.6e-6,
    // T_DSU + T_SCLH + T_DH = 1 / (BUS FREQ)
    // !!! Be sure T_DSU is the maximum one !!!
    parameter real T_DSU  = 1.3e-6,
    parameter real T_SCLH = 0.9e-6,
    parameter real T_DH   = 0.3e-6,
    parameter real T_PSU  = 0.6e-6,
    parameter real T_PH   = 0.7e-6
)
(
    input wire csi_clk,
    input wire csi_reset,
    (* mark_debug = "true" *)
    input wire [1:0] avs_address,
    input wire avs_write,
    input wire [31:0] avs_writedata,
    input wire [3:0] avs_byteenable,
    input wire avs_read,                 // read latency = 1
    (* mark_debug = "true" *)
    output wire [31:0] avs_readdata,
    input  wire axi_rShaked,
    output wire ins_irq,
//    inout coe_scl,
//    inout coe_sda

    input wire scl_i,
    output wire scl_o,
    output wire scl_t,
    
    input wire sda_i,
    output wire sda_o,
    output wire sda_t
);

    localparam TX_FIFO_CNT_WIDTH = 10;
    localparam RX_FIFO_CNT_WIDTH = 11;
    
    reg [1:0] int_mask;
    wire [1:0] int_status;
    // tx fifo wires
    (* mark_debug = "true" *) wire tx_fifo_wr = avs_write & (avs_address == 2'h0) & (&avs_byteenable[1:0]);
    (* mark_debug = "true" *) wire [9:0] tx_fifo_data = avs_writedata[9:0];
    (* mark_debug = "true" *) wire tx_fifo_rd;
    (* mark_debug = "true" *) wire [9:0] tx_fifo_q;
    (* mark_debug = "true" *) wire [TX_FIFO_CNT_WIDTH - 1 : 0] tx_fifo_usedw;
    (* mark_debug = "true" *) wire tx_fifo_full;
    (* mark_debug = "true" *) wire tx_fifo_empty;
    wire [15:0] tx_fifo_dw = {tx_fifo_full, tx_fifo_usedw};
    // rx fifo wires
    (* mark_debug = "true" *) wire rx_fifo_wr;
    (* mark_debug = "true" *) wire [8:0] rx_fifo_data;
    (* mark_debug = "true" *) wire rx_fifo_rd = avs_read & (avs_address == 2'h0);// & (&avs_byteenable[3:2]); modified 20200529, zynq ps give meaningless wstrb while reading
    (* mark_debug = "true" *) wire [8:0] rx_fifo_q;
    (* mark_debug = "true" *) wire [RX_FIFO_CNT_WIDTH - 1 : 0] rx_fifo_usedw;
    (* mark_debug = "true" *) wire rx_fifo_full;
    (* mark_debug = "true" *) wire rx_fifo_empty;
    wire [15:0] rx_fifo_dw = {rx_fifo_full, rx_fifo_usedw};
    
    // avs read
    reg [31:0] readdata;
    reg rx_fifo_rd_dly;
    (* mark_debug = "true" *)
    reg is_axiReading;
    always@(posedge csi_clk)begin
        if(csi_reset)begin
            is_axiReading <= 0;
        end
        else begin
            if(rx_fifo_rd)begin
                is_axiReading <= 1'b1;
            end
            else if(axi_rShaked)begin
                is_axiReading <= 1'b0;
            end
            else begin
                is_axiReading <= is_axiReading;
            end
        end
    end 

    assign avs_readdata = is_axiReading? {7'b0, rx_fifo_q, 16'b0} : readdata;   //Modified by jiaxiang Feng
    always@(posedge csi_clk) begin
        rx_fifo_rd_dly <= rx_fifo_rd;
        readdata <= (avs_address == 2'h1)? {rx_fifo_dw, tx_fifo_dw} :
                                           {22'b0, int_mask, 6'b0, int_status};
    end
    
    // write
    reg [15:0] rx_almost_full_th, tx_almost_empty_th;
    always@(posedge csi_clk) begin
        if(csi_reset) begin
            rx_almost_full_th <= 16'h40;
            tx_almost_empty_th <= 16'h0;
            int_mask <= 2'b0;
        end
        else begin
            if(avs_write)
            begin
                if(avs_address == 2'h1)
                begin
                    if(&avs_byteenable[1:0])
                    begin
                        tx_almost_empty_th[15:0] <= avs_writedata[15:0];
                    end
                    if(&avs_byteenable[3:2])
                    begin
                        rx_almost_full_th[15:0] <= avs_writedata[31:16];
                    end
                end
                else if(avs_address == 2'h2)
                begin
                    if(avs_byteenable[1])
                    begin
                        int_mask <= avs_writedata[9:8];
                    end
                end
            end
        end
    end
    
    // irq generate
    assign int_status = {(rx_fifo_dw >= rx_almost_full_th), (tx_fifo_dw <= tx_almost_empty_th)};
    assign ins_irq = |(int_status & int_mask);
    
    // tx_fifo
//    iic_tx_fifo	iic_tx_fifo_inst (
//        .clock ( csi_clk ),
//        .data ( tx_fifo_data ),
//        .rdreq ( tx_fifo_rd ),
//        .sclr ( csi_reset ),
//        .wrreq ( tx_fifo_wr ),
//        .empty ( tx_fifo_empty ),
//        .full ( tx_fifo_full ),
//        .q ( tx_fifo_q ),
//        .usedw ( tx_fifo_usedw )
//	);
	
	wire [TX_FIFO_CNT_WIDTH - 1 : 0] tx_fifo_rdcount, tx_fifo_wrcount;
	assign tx_fifo_usedw = tx_fifo_wrcount - tx_fifo_rdcount;
    FIFO_SYNC_MACRO  #(
      .DEVICE("7SERIES"),           // Target Device: "7SERIES" 
      .ALMOST_EMPTY_OFFSET(9'h080), // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(9'h080),  // Sets almost full threshold
      .DATA_WIDTH(10),              // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      .DO_REG(0),                   // Optional output register (0 or 1)
      .FIFO_SIZE ("18Kb")           // Target BRAM: "18Kb" or "36Kb" 
    ) iic_tx_fifo_inst (
      .ALMOSTEMPTY  (                               ),  // 1-bit output almost empty
      .ALMOSTFULL   (                               ),  // 1-bit output almost full
      .DO           (tx_fifo_q                      ),  // Output data, width defined by DATA_WIDTH parameter
      .EMPTY        (tx_fifo_empty                  ),  // 1-bit output empty
      .FULL         (tx_fifo_full                   ),  // 1-bit output full
      .RDCOUNT      (tx_fifo_rdcount                ),  // Output read count, width determined by FIFO depth
      .RDERR        (                               ),  // 1-bit output read error
      .WRCOUNT      (tx_fifo_wrcount                ),  // Output write count, width determined by FIFO depth
      .WRERR        (                               ),  // 1-bit output write error
      .CLK          (csi_clk                        ),  // 1-bit input clock
      .DI           (tx_fifo_data                   ),  // Input data, width defined by DATA_WIDTH parameter
      .RDEN         (tx_fifo_rd & (~tx_fifo_empty)  ),  // 1-bit input read enable
      .RST          (csi_reset                      ),  // 1-bit input reset
      .WREN         (tx_fifo_wr & (~tx_fifo_full)   )   // 1-bit input write enable
    );                  
            
    // rx_fifo
//    iic_rx_fifo	iic_rx_fifo_inst (
//        .clock ( csi_clk ),
//        .data ( rx_fifo_data ),
//        .rdreq ( rx_fifo_rd ),
//        .sclr ( csi_reset ),
//        .wrreq ( rx_fifo_wr ),
//        .empty ( rx_fifo_empty ),
//        .full ( rx_fifo_full ),
//        .q ( rx_fifo_q ),
//        .usedw ( rx_fifo_usedw )
//	);
	wire [RX_FIFO_CNT_WIDTH - 1 : 0] rx_fifo_rdcount, rx_fifo_wrcount;
	assign rx_fifo_usedw = rx_fifo_wrcount - rx_fifo_rdcount;
    FIFO_SYNC_MACRO  #(
      .DEVICE("7SERIES"),           // Target Device: "7SERIES" 
      .ALMOST_EMPTY_OFFSET(9'h080), // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(9'h080),  // Sets almost full threshold
      .DATA_WIDTH(9),              // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      .DO_REG(0),                   // Optional output register (0 or 1)
      .FIFO_SIZE ("18Kb")           // Target BRAM: "18Kb" or "36Kb" 
    ) iic_rx_fifo_inst (
      .ALMOSTEMPTY  (                               ),  // 1-bit output almost empty
      .ALMOSTFULL   (                               ),  // 1-bit output almost full
      .DO           (rx_fifo_q                      ),  // Output data, width defined by DATA_WIDTH parameter
      .EMPTY        (rx_fifo_empty                  ),  // 1-bit output empty
      .FULL         (rx_fifo_full                   ),  // 1-bit output full
      .RDCOUNT      (rx_fifo_rdcount                ),  // Output read count, width determined by FIFO depth
      .RDERR        (                               ),  // 1-bit output read error
      .WRCOUNT      (rx_fifo_wrcount                ),  // Output write count, width determined by FIFO depth
      .WRERR        (                               ),  // 1-bit output write error
      .CLK          (csi_clk                        ),  // 1-bit input clock
      .DI           (rx_fifo_data                   ),  // Input data, width defined by DATA_WIDTH parameter
      .RDEN         (rx_fifo_rd & (~rx_fifo_empty)  ),  // 1-bit input read enable
      .RST          (csi_reset                      ),  // 1-bit input reset
      .WREN         (rx_fifo_wr & (~rx_fifo_full)   )   // 1-bit input write enable
    );                  

    // iic master engine
    iic_master_engine
    #(
        .CLK_FREQ(CLK_FREQ),
        .T_SSU(T_SSU),
        .T_SH(T_SH),
        .T_DSU(T_DSU),
        .T_SCLH(T_SCLH),
        .T_DH(T_DH),
        .T_PSU(T_PSU),
        .T_PH(T_PH)
    )
    iic_master_engine_inst
    (
        .clk(csi_clk),
        .arst(csi_reset),
        .trans_fifo_q(tx_fifo_q),
        .trans_fifo_rd(tx_fifo_rd),
        .trans_fifo_empty(tx_fifo_empty),
        .recv_fifo_data(rx_fifo_data),
        .recv_fifo_wr(rx_fifo_wr),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t)
    );
    
endmodule

