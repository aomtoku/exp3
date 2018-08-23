/******************************************************************
 * SDAR module                                                    *
 * All rights reserved (C) 2018 Yuta Tokusashi                    *
 *****************************************************************/
`timescale 1ns/1ps
`include "wombat_cpu_regs_defines.v"

module wombat #(
	//Master AXI Stream Data Width
	parameter C_M_AXIS_DATA_WIDTH  = 256,
	parameter C_S_AXIS_DATA_WIDTH  = 256,
	parameter C_M_AXIS_TUSER_WIDTH = 128,
	parameter C_S_AXIS_TUSER_WIDTH = 128,
	parameter SRC_PORT_POS         = 16,
	parameter DST_PORT_POS         = 24,
	parameter NUM_OUTPUT_QUEUES    = 8,

	// AXI Registers Data Width
	parameter C_S_AXI_DATA_WIDTH   = 32,          
	parameter C_S_AXI_ADDR_WIDTH   = 12,          
	parameter C_USE_WSTRB          = 0,
	parameter C_DPHASE_TIMEOUT     = 0,               
	parameter C_NUM_ADDRESS_RANGES = 1,
	parameter C_TOTAL_NUM_CE       = 1,
	parameter C_S_AXI_MIN_SIZE     = 32'h0000_FFFF,
	parameter [0:8*C_NUM_ADDRESS_RANGES-1] C_ARD_NUM_CE_ARRAY  = 
	                                            {
	                                             C_NUM_ADDRESS_RANGES{8'd1}
	                                             },
	parameter C_FAMILY             = "virtex7", 
	parameter C_BASEADDR           = 32'h00000000,
	parameter C_HIGHADDR           = 32'h0000FFFF
) (
	// Global Ports
	input                                      axis_aclk,
	input                                      axis_resetn,
	
	// Master Stream Ports (interface to data path)
	output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_tdata,
	output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
	output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_tuser,
	output                                     m_axis_tvalid,
	input                                      m_axis_tready,
	output                                     m_axis_tlast,
	
	// Slave Stream Ports (interface to RX queues)
	input [C_S_AXIS_DATA_WIDTH - 1:0]          s_axis_tdata,
	input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]  s_axis_tkeep,
	input [C_S_AXIS_TUSER_WIDTH-1:0]           s_axis_tuser,
	input                                      s_axis_tvalid,
	output                                     s_axis_tready,
	input                                      s_axis_tlast,

	// Slave AXI Ports
	input                                     S_AXI_ACLK,
	input                                     S_AXI_ARESETN,
	input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
	input                                     S_AXI_AWVALID,
	input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
	input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB,
	input                                     S_AXI_WVALID,
	input                                     S_AXI_BREADY,
	input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
	input                                     S_AXI_ARVALID,
	input                                     S_AXI_RREADY,
	output                                    S_AXI_ARREADY,
	output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
	output     [1 : 0]                        S_AXI_RRESP,
	output                                    S_AXI_RVALID,
	output                                    S_AXI_WREADY,
	output     [1 :0]                         S_AXI_BRESP,
	output                                    S_AXI_BVALID,
	output                                    S_AXI_AWREADY
);

function integer log2;
input integer number;
begin
	log2=0;
	while(2**log2<number) begin
		log2=log2+1;
	end
end
endfunction // log2

/***********************************************************
 * Reset 
 ***********************************************************/
reg [1:0] axis_resetn_vec0 = 2'b11;
reg [3:0] axis_resetn_vec1 = 4'b1111;
reg [7:0] axis_resetn_vec2 = 8'b1111_1111;
always @ (posedge axis_aclk) begin
	axis_resetn_vec0 <= (axis_resetn) ? 2'b11 : 2'b00;
	axis_resetn_vec1 <= (axis_resetn_vec0 == 2'b11) ? 4'b1111 : 4'b0000;
	axis_resetn_vec2 <= (axis_resetn_vec1 == 4'b1111) ? 8'b1111_1111 : 8'b0000_0000;
end

/***********************************************************
 * Parameter : Header Position and Length
 ***********************************************************/
// Ethernet Frame Header
localparam ETH_DST_MAC_POS   = 0;
localparam ETH_SRC_MAC_POS   = 48;
localparam ETH_TYPE_POS      = 96;
// IP Header
localparam IP_VER_POS        = 112;
localparam IP_IHL_POS        = 116;
localparam IP_TOS_POS        = 120;
localparam IP_LEN_POS        = 128;
localparam IP_IDENT_POS      = 144;
localparam IP_FRAG_POS       = 160;
localparam IP_TTL_POS        = 176;
localparam IP_PROTO_POS      = 184;
localparam IP_CSUM_POS       = 192;
localparam IP_SRC_ADDR_POS   = 208;
localparam IP_DST_ADDR_POS0  = 240;
localparam IP_DST_ADDR_POS1  = 0;
// UDP Header 
localparam UDP_SRC_UPORT_POS = 16;
localparam UDP_DST_UPORT_POS = 32;
localparam UDP_LEN_POS       = 48;
localparam UDP_CSUM_POS      = 64;
// Datagram
localparam USER_DATA_POS     = 80;
localparam USER_DATA_LEN     = 32;

/***********************************************************
 * Parameter : 
 ***********************************************************/
localparam STATUS_IP         = 0;
localparam STATUS_UDP        = 1;
localparam STATUS_PORT       = 2;

localparam IP_TYPE           = 16'h0008;
localparam UDP_PROTO         =  8'h11;

//`ifdef SIMULATION_DEBUG
//localparam UDP_PORT_TRIG     = 16'h0f00;
//`else
localparam UDP_PORT_TRIG     = 16'd12345;
//`endif

localparam SMOOTH	     = 5;
localparam FORGETABILITY     = 32'h3ca3d70a;
localparam ORDER	     = 2;

/***********************************************************
 * Parser for incoming packet 
 ***********************************************************/
reg s_axis_ready_latch, s_axis_ready_latch_d;
reg [7:0]  s_axis_cnt;
reg [7:0]  status;
`ifdef SIMULATION_DEBUG
wire [15:0] udp_port = (s_axis_cnt == 1) ? s_axis_tdata[UDP_DST_UPORT_POS+15:UDP_DST_UPORT_POS] : 0;
`endif
/* tokusashi 20170919 : This register is used for input of sdar. */
wire udp_en = (s_axis_cnt == 1) && 
          s_axis_tdata[UDP_DST_UPORT_POS+15:UDP_DST_UPORT_POS] == UDP_PORT_TRIG;
//reg [31:0] user_value;
wire       user_value_valid = status[STATUS_IP]   == 1'b1 &&
                              status[STATUS_UDP]  == 1'b1 &&
                              udp_en == 1'b1;
wire [31:0] user_value = s_axis_tdata[USER_DATA_POS+USER_DATA_LEN-1:USER_DATA_POS];
reg [255:0] pkt_data;
reg [176:0] tmp_data;
reg         pkt_en, last_reg;

always @ (posedge axis_aclk) begin
	if (!axis_resetn_vec2[0]) begin
		s_axis_cnt <= 0;
		status     <= 0;
		pkt_data  <= 0;
		tmp_data  <= 0;
		pkt_en    <=0;
		last_reg  <=0;
		//user_value <= 0;
	end else begin
		if (s_axis_tvalid && s_axis_tready) begin
			$display("[%d] s_axis_tdata[ETH_TYPE] %x, s_axis_tdata[IP_PROTO] %x", 
				s_axis_cnt, s_axis_tdata[ETH_TYPE_POS+15:ETH_TYPE_POS], s_axis_tdata[IP_PROTO_POS+7:IP_PROTO_POS]);
			case (s_axis_cnt)
				0: begin
					if (s_axis_tdata[ETH_TYPE_POS+15:ETH_TYPE_POS] == IP_TYPE) 
						status[STATUS_IP] <= 1'b1;
					if (s_axis_tdata[IP_PROTO_POS+7:IP_PROTO_POS] == UDP_PROTO)
						status[STATUS_UDP] <= 1'b1;
				end
				1: begin	
					$display("s_axis_tdata[UDP_DST_UPORT_POS+15:UDP_DST_UPORT_POS]: %d", s_axis_tdata[UDP_DST_UPORT_POS+15:UDP_DST_UPORT_POS]);
					if ({s_axis_tdata[UDP_DST_UPORT_POS+7:UDP_DST_UPORT_POS], s_axis_tdata[UDP_DST_UPORT_POS+15:UDP_DST_UPORT_POS+8]} == UDP_PORT_TRIG) 
						status[STATUS_PORT] <= 1'b1;
						tmp_data[175:0] <= s_axis_tdata[255:80];
					//user_value <= s_axis_tdata[USER_DATA_POS+USER_DATA_LEN-1:USER_DATA_POS];
				end
				default: ;
			endcase
			if (status[2:0] == 3'b111) begin
				pkt_en <= 1;
				pkt_data <= {s_axis_tdata[79:0], tmp_data[175:0]};
				tmp_data <= s_axis_tdata[255:80];
			end

			if (s_axis_tlast) begin
				s_axis_ready_latch <= 0;
				s_axis_cnt         <= 0;
				last_reg           <= 1;
			end else begin
				s_axis_ready_latch <= 1;
				s_axis_cnt         <= s_axis_cnt + 1;
			end
		end else begin
			last_reg <= 0;
		end
		if (last_reg) begin
			pkt_en <= 0;
			status <= 0;
		end
		// Last flit of outgoing Packet
	//	if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
	//		status <= 0;
	//	end
	end
end

always @ (*) begin
	s_axis_ready_latch_d = (s_axis_tvalid && s_axis_tready && s_axis_cnt == 0) ? 1 : s_axis_ready_latch;
end

/***********************************************************
 *  Clock generation and Reset
 ***********************************************************/
reg  cf_clk_reg = 0;
wire cf_clk;
reg  cf_start;
reg  [31:0] cf_count;
wire cf_done, cf_ready, cf_idle;
reg  [31:0] input_r_0;
wire [255:0] cf_return_value;
wire cf_80m_clk, cf_125m_clk;
// Clocking
//always @ (posedge axis_aclk)
//	cf_clk_reg <= ~cf_clk_reg;
//
//BUFG u_bufg (
//	.I (cf_clk_reg),
//	.O (cf_80m_clk)
//);
//
//mmcm_wrapper u_mmcm_wrapper (
//	.inclk    ( cf_80m_clk   ),
//	.inrst    ( !axis_resetn ),
//	.dout_clk ( cf_125m_clk ),
//	.dout_rst ( )
//);

/* tokusashi 20171211: You can choose clock 80M or 125M */
assign cf_clk = cf_80m_clk;

// Reset
reg [7:0] cf_rst_cnt = 0;
always @ (posedge cf_clk)
`ifdef SIMULATION_DEBUG
	if (cf_rst_cnt != 8'h02)
`else
	if (cf_rst_cnt != 8'hff)
`endif
		cf_rst_cnt <= cf_rst_cnt + 1;

`ifdef SIMULATION_DEBUG
wire cf_rstn = cf_rst_cnt == 8'h02 ? 1'b1 : 1'b0;
`else
wire cf_rstn = cf_rst_cnt == 8'hff ? 1'b1 : 1'b0;
`endif

/***********************************************************
 *  Instance : RAMDOM based on PRBS
 ***********************************************************/
wire [30:0] random_p;

prbs #(
	.WIDTH(31)	   //WIDTH is the size of the data bus
) u_prbs (
`ifdef VAR_FREQ
	.clk     ( cf_clk      ),
	.rstn    ( cf_rstn     ),
`else
	.clk     ( axis_aclk   ),
	.rstn    ( axis_resetn_vec2[1] ),
`endif
	.do      ( random_p    ),
	.advance ( 1'b1        )
);

/***********************************************************
 *  Logic for wombat and packet dataplane
 ***********************************************************/
wire [255:0] input_r;
wire empty_i, full_i;
wire sample_valid;
wire ap_return_valid;
wire mode_reg_clear;
wire [31:0] sample_mode;
reg sample_mode_reg;

assign sample_mode = {31'd0, sample_mode_reg};

`ifdef VAR_FREQ
always @ (posedge cf_clk) begin
	if (!cf_rstn) begin
`else
always @ (posedge axis_aclk) begin
	if (!axis_resetn_vec2[7]) begin
`endif 
		sample_mode_reg <= 0;
	end else begin
	// Tokusashi 20180816: mode_reg_clear runs on 200MHz.
	//    This signal would be async.
		if (mode_reg_clear) begin
			sample_mode_reg <= 0;
		end else if (sample_valid) begin
			sample_mode_reg <= 1;
		end
	end
end
wire start_en = (cf_idle && !empty_i) || (cf_start && cf_ready && !empty_i) 
                   || (!cf_idle && !cf_start && !empty_i);


`ifdef VAR_FREQ
asfifo #(
	.DATA_WIDTH     (256),
	.ADDRESS_WIDTH  (4)
) u_fifo_i (
	.dout     ( input_r              ), 
	.empty    ( empty_i              ),
	.rd_en    ( sample_valid         ),
	.rd_clk   ( cf_clk               ),        
	.din      ( pkt_data             ),  
	.full     ( full_i               ),
	.wr_en    ( pkt_en               ),
	.wr_clk   ( axis_aclk            ),
	.rst      ( !axis_resetn_vec2[5] ) 
);
`else
wire nearly_full, nearly_full_i;
exp3_fallthrough_small_fifo #(
	.WIDTH           (256),
	.MAX_DEPTH_BITS  (8)
) u_fifo_i (
	.din           ( pkt_data ),
	.wr_en         ( pkt_en ),
	.rd_en         ( sample_valid && !empty_i ),

	.dout          ( input_r ),
	.full          ( full_i        ),
	.nearly_full   ( nearly_full_i ),
	.prog_full     (),
	.empty         ( empty_i  ),

	.reset         ( !axis_resetn_vec2[5] ),
	.clk           ( axis_aclk    )
);
`endif /*VAR_FREQ*/

/***********************************************************
 *  Instance : Wombat
 ***********************************************************/
wire [31:0] gamma_wire;

sample u_sample (
`ifdef VAR_FREQ
	.ap_clk        ( cf_clk    ),
	.ap_rst        ( !cf_rstn  ),
`else
	.ap_clk        ( axis_aclk    ),
	.ap_rst        ( !axis_resetn_vec2[6]  ),
`endif
	.ap_start      ( cf_start  ),
	.ap_done       ( cf_done   ),
	.ap_idle       ( cf_idle   ),
	.ap_ready      ( cf_ready  ),
	.in_V_V_dout   ( input_r  ),
	.in_V_V_empty_n( !empty_i  ),
	.in_V_V_read   ( sample_valid ),
	.gamma         ( gamma_wire ),
	.p             ( {7'd0, random_p[22:0]}     ),
	.mode          ( sample_mode  ),
	.ap_return     ( cf_return_value )
);

`ifdef VAR_FREQ
always @ (posedge cf_clk) begin
	if (!cf_rstn) begin
`else
always @ (posedge axis_aclk) begin
	if (!axis_resetn_vec2[7]) begin
`endif 
		cf_start <= 1'b0;
		input_r_0 <= 0;
	end else begin
		if (cf_ready && empty_i) begin
			cf_start <= 1'b0;
		end else if (cf_ready && !empty_i) begin
			input_r_0 <= input_r;
		end else if (start_en) begin
			cf_start <= 1'b1;
			input_r_0 <= input_r;
		end else if (!cf_idle && !cf_start && !empty_i) begin
			cf_start <= 1'b1;
			input_r_0 <= input_r;
		end
	end
end

`ifdef VAR_FREQ
always @ (posedge cf_clk) begin
	if (!cf_rstn) begin
`else
always @ (posedge axis_aclk) begin
	if (!axis_resetn_vec2[4]) begin
`endif 
		cf_count <= 0;
	end else begin
		if(cf_done)		
			cf_count <= cf_count + 1;
	end
end

wire empty, full;
wire [31:0] dout_return_value;

`ifdef VAR_FREQ
asfifo #(
	.DATA_WIDTH     (32),
	.ADDRESS_WIDTH  (3)
) u_fifo_o (
	.dout     (dout_return_value), 
	.empty    (empty),
	.rd_en    (!empty),
	.rd_clk   (axis_aclk),        
	.din      (cf_return_value[31:0]),  
	.full     (full),
	.wr_en    (cf_done),
	//.wr_en    (ap_return_valid),
	.wr_clk   (cf_clk),
	.rst      (!axis_resetn_vec2[1]) 
);
`else
exp3_fallthrough_small_fifo #(
	.WIDTH           (32),
	.MAX_DEPTH_BITS  (3)
) u_fifo_o (
	.din           ( cf_return_value[31:0] ),
	.wr_en         ( cf_done ),
	.rd_en         ( !empty  ),

	.dout          ( dout_return_value ),
	.full          ( full        ),
	.nearly_full   ( nearly_full ),
	.prog_full     (),
	.empty         ( empty  ),

	.reset         ( !axis_resetn_vec2[3] ),
	.clk           ( axis_aclk    )
);
`endif /*VAR_FREQ*/

reg return_valid;
reg [31:0] return_value;
always @ (posedge axis_aclk) begin
	if (!axis_resetn_vec2[2]) begin
		return_value <= 0;
		return_valid <= 0;
	end else begin
		if (!empty) begin
			return_value <= dout_return_value;
		end
		return_valid <= (!empty) ? 1'b1 : 1'b0;
	end
end


/***********************************************************
 * Output Packets
 ***********************************************************/
/* tokusashi 20170919: What do you want to do here?? */
assign m_axis_tdata  = s_axis_tdata ;
assign m_axis_tkeep  = s_axis_tkeep ;
assign m_axis_tuser  = s_axis_tuser ;
assign m_axis_tvalid = s_axis_tvalid;
assign m_axis_tlast  = s_axis_tlast ;

assign s_axis_tready = m_axis_tready;

/***********************************************************
 *  Instance : Registers
 ***********************************************************/
reg  [`REG_ID_BITS]       id_reg;
reg  [`REG_VERSION_BITS]  version_reg;
wire [`REG_RESET_BITS]    reset_reg;
reg  [`REG_FLIP_BITS]     ip2cpu_flip_reg;
wire [`REG_FLIP_BITS]     cpu2ip_flip_reg;
reg  [`REG_PKTIN_BITS]    pktin_reg;
wire                      pktin_reg_clear;
reg  [`REG_PKTOUT_BITS]   pktout_reg;
wire                      pktout_reg_clear;
reg  [`REG_DEBUG_BITS]    ip2cpu_debug_reg;
wire [`REG_DEBUG_BITS]    cpu2ip_debug_reg;

wire return_value_clear;
reg [31:0] return_value_reg;

wire clear_counters;
wire reset_registers;
wire reset_tables;
wire resetn_sync;
wombat_cpu_regs #(
	.C_S_AXI_DATA_WIDTH ( C_S_AXI_DATA_WIDTH ),
	.C_S_AXI_ADDR_WIDTH ( C_S_AXI_ADDR_WIDTH ),
	.C_BASE_ADDRESS     ( C_BASEADDR         )
) u_wombat_regs (   
	// General ports
	.clk                    (axis_aclk),
	.resetn                 (axis_resetn_vec2[3]),
	// AXI Lite ports
	.S_AXI_ACLK             (S_AXI_ACLK),
	.S_AXI_ARESETN          (S_AXI_ARESETN),
	.S_AXI_AWADDR           (S_AXI_AWADDR),
	.S_AXI_AWVALID          (S_AXI_AWVALID),
	.S_AXI_WDATA            (S_AXI_WDATA),
	.S_AXI_WSTRB            (S_AXI_WSTRB),
	.S_AXI_WVALID           (S_AXI_WVALID),
	.S_AXI_BREADY           (S_AXI_BREADY),
	.S_AXI_ARADDR           (S_AXI_ARADDR),
	.S_AXI_ARVALID          (S_AXI_ARVALID),
	.S_AXI_RREADY           (S_AXI_RREADY),
	.S_AXI_ARREADY          (S_AXI_ARREADY),
	.S_AXI_RDATA            (S_AXI_RDATA),
	.S_AXI_RRESP            (S_AXI_RRESP),
	.S_AXI_RVALID           (S_AXI_RVALID),
	.S_AXI_WREADY           (S_AXI_WREADY),
	.S_AXI_BRESP            (S_AXI_BRESP),
	.S_AXI_BVALID           (S_AXI_BVALID),
	.S_AXI_AWREADY          (S_AXI_AWREADY),
   
	// Register ports
	.id_reg                 (id_reg),
	.version_reg            (version_reg),
	.return_value           (return_value_reg),
	.tput_reg               (cf_count),
	.return_value_clear     (return_value_clear),
	.gamma_reg              (gamma_wire),
	.mode_reg_clear         (mode_reg_clear),
	.reset_reg              (reset_reg),
	.ip2cpu_flip_reg        (ip2cpu_flip_reg),
	.cpu2ip_flip_reg        (cpu2ip_flip_reg),
	.pktin_reg              (pktin_reg),
	.pktin_reg_clear        (pktin_reg_clear),
	.pktout_reg             (pktout_reg),
	.pktout_reg_clear       (pktout_reg_clear),
	//.luthit_reg             (luthit_reg),
	//.luthit_reg_clear       (luthit_reg_clear),
	//.lutmiss_reg            (lutmiss_reg),
	//.lutmiss_reg_clear      (lutmiss_reg_clear),
	
	.ip2cpu_debug_reg       (ip2cpu_debug_reg),
	.cpu2ip_debug_reg       (cpu2ip_debug_reg),
	// Global Registers - user can select if to use
	.cpu_resetn_soft        (),
	.resetn_soft            (),
	.resetn_sync            (resetn_sync)
);

assign clear_counters =  reset_reg[0];
assign reset_registers = reset_reg[4];
assign reset_tables   =  reset_reg[8];

// todo : axis_resetn is changing to new reset signal for cf_clk
always @ (posedge cf_clk) 
	if (!axis_resetn_vec2[4]) begin
		return_value_reg <= 0;
	end else begin
		if (clear_counters || return_value_clear)
			return_value_reg <= 0;
		else if (return_valid)
			return_value_reg <= return_value;
	end

always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		id_reg           <= #1 `REG_ID_DEFAULT;
		version_reg      <= #1 `REG_VERSION_DEFAULT;
		ip2cpu_flip_reg  <= #1 `REG_FLIP_DEFAULT;
		pktin_reg        <= #1 `REG_PKTIN_DEFAULT;
		pktout_reg       <= #1 `REG_PKTOUT_DEFAULT;
		//luthit_reg       <= #1 `REG_LUTHIT_DEFAULT;
		//lutmiss_reg      <= #1 `REG_LUTMISS_DEFAULT;
		ip2cpu_debug_reg <= #1 `REG_DEBUG_DEFAULT;
	end else begin
		id_reg          <= #1    `REG_ID_DEFAULT;
		version_reg     <= #1    `REG_VERSION_DEFAULT;
		ip2cpu_flip_reg <= #1    ~cpu2ip_flip_reg;


		pktin_reg[`REG_PKTIN_WIDTH -2: 0] <= #1  clear_counters | pktin_reg_clear ? 'h0  : pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_tlast && s_axis_tvalid && s_axis_tready) ;
                pktin_reg[`REG_PKTIN_WIDTH-1] <= #1 clear_counters | pktin_reg_clear ? 1'h0   : pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_tlast && s_axis_tvalid && s_axis_tready) 
                                                     > {(`REG_PKTIN_WIDTH-1){1'b1}} ? 1'b1 : pktin_reg[`REG_PKTIN_WIDTH-1];
                                                               
		pktout_reg [`REG_PKTOUT_WIDTH-2:0]<= #1  clear_counters | pktout_reg_clear ? 'h0  : pktout_reg [`REG_PKTOUT_WIDTH-2:0] + (m_axis_tvalid && m_axis_tlast && m_axis_tready) ;
                pktout_reg [`REG_PKTOUT_WIDTH-1]<= #1  clear_counters | pktout_reg_clear ? 'h0  : pktout_reg [`REG_PKTOUT_WIDTH-2:0] + (m_axis_tvalid && m_axis_tlast && m_axis_tready)  > {(`REG_PKTOUT_WIDTH-1){1'b1}} ?
                                                                1'b1 : pktout_reg [`REG_PKTOUT_WIDTH-1];
	//	luthit_reg[`REG_LUTHIT_WIDTH -2: 0] <= #1  clear_counters | luthit_reg_clear ? 'h0  : luthit_reg[`REG_LUTHIT_WIDTH-2:0] + (lut_hit & lookup_done) ;
    //            luthit_reg[`REG_LUTHIT_WIDTH-1] <= #1 clear_counters | luthit_reg_clear ? 1'h0 : luthit_reg_clear ? 'h0  : luthit_reg[`REG_LUTHIT_WIDTH-2:0] + (lut_hit & lookup_done)
    //                                                 > {(`REG_LUTHIT_WIDTH-1){1'b1}} ? 1'b1 : pktin_reg[`REG_LUTHIT_WIDTH-1];
    //                                                           
	//	lutmiss_reg [`REG_LUTMISS_WIDTH-2:0]<= #1  clear_counters | lutmiss_reg_clear ? 'h0  : lutmiss_reg [`REG_LUTMISS_WIDTH-2:0] + (lut_miss & lookup_done) ;
    //            lutmiss_reg [`REG_LUTMISS_WIDTH-1]<= #1  clear_counters | lutmiss_reg_clear ? 'h0  : lutmiss_reg [`REG_LUTMISS_WIDTH-2:0] + (lut_miss & lookup_done)  > {(`REG_LUTMISS_WIDTH-1){1'b1}} ?
    //                                                            1'b1 : lutmiss_reg [`REG_LUTMISS_WIDTH-1];

		ip2cpu_debug_reg <= #1    `REG_DEBUG_DEFAULT+cpu2ip_debug_reg;
        end


// Debug
`ifndef SIMULATION_DEBUG
ila_0 u_ila (
	.clk      (axis_aclk),
	.probe0   ({20'h0,
	            input_r,
	            cf_rst_cnt,
	            user_value_valid,
	            udp_en,
	            cf_idle,
	            cf_start,
	            cf_ready,
				cf_done,
	            start_en,
		        s_axis_cnt[7:0], 
	            s_axis_tdata[UDP_DST_UPORT_POS+15:UDP_DST_UPORT_POS],
	            empty, 
				s_axis_tvalid, 
				s_axis_tready, 
				status[3:0], 
				return_value[31:0]
	})
);
`endif /* SIMULATION */
endmodule
