`timescale 1ns/1ps
`define SIMULATION
/******************************************************************
 * Testbench for SDAR module                                      *
 * All rights reserved (C) 2017 Yuta Tokusashi                    *
 *****************************************************************/
module tb_sim ();

localparam NF_CLK_PERIOD = 3.125;
localparam RESET_PERIOD  = NF_CLK_PERIOD * 20;

//*****************************************************************
// Reset Generation
//*****************************************************************
reg sys_rst_n;
wire sys_rst;

initial begin
	sys_rst_n = 1'b0;
	#RESET_PERIOD
	sys_rst_n = 1'b1;
end

//*****************************************************************
// Clock Generation
//*****************************************************************
reg nf_clk_i;

initial
	nf_clk_i = 1'b0;
always
	nf_clk_i = #NF_CLK_PERIOD ~nf_clk_i;

//*****************************************************************
// Task 
//*****************************************************************
task waitaclk;
begin
	@(posedge nf_clk_i);
end
endtask

task waitclk;
input integer max;
integer i;
begin
	for (i = 0; i < max; i = i + 1)
		waitaclk;
end
endtask
//*****************************************************************
// Monitor
//*****************************************************************
reg [31:0] sys_cnt = 0;
always @ (posedge nf_clk_i) begin
	sys_cnt <= sys_cnt + 1;
end

always @ (posedge u_wombat.axis_aclk) begin
	if (u_wombat.user_value_valid) begin
		$write("%c[1;34m",27); 
		$display("Clk[%8d] Triggered Data: %x",sys_cnt, u_wombat.user_value);
		$write("%c[0m",27); 
	end
end

always @ (posedge u_wombat.axis_aclk) begin
	if (u_wombat.return_valid) begin
		$write("%c[1;34m",27); 
		$display("Clk[%8d] Return Data: %x",sys_cnt, u_wombat.return_value);
		$write("%c[0m",27); 
	end
end
always @ (posedge u_wombat.cf_clk) begin
	if (u_wombat.cf_done) begin
		$write("%c[1;34m",27); 
		$display("Clk[%8d] Output Data : %x", sys_cnt, u_wombat.cf_return_value);
		$write("%c[0m",27); 
	end
	if (u_wombat.start_en) begin
		$write("%c[1;34m",27); 
		$display("Clk[%8d] Input Data  : %x", sys_cnt, u_wombat.input_r);
		$write("%c[0m",27); 
	end
end

wire [255:0] m_axis_tdata ;
wire [31:0]  m_axis_tkeep ;
wire [127:0] m_axis_tuser ;
wire         m_axis_tvalid;
wire         m_axis_tready;
wire         m_axis_tlast ;

reg [255:0] s_axis_tdata ;
reg [ 31:0] s_axis_tkeep ;
reg [127:0] s_axis_tuser ;
reg         s_axis_tvalid;
reg         s_axis_tlast ;
wire        s_axis_tready;

wombat u_wombat (
	// Global Ports
	.axis_aclk     ( nf_clk_i  ),
	.axis_resetn   ( sys_rst_n ),
	
	// Master Stream Ports (interface to data path)
	.m_axis_tdata  ( m_axis_tdata  ),
	.m_axis_tkeep  ( m_axis_tkeep  ),
	.m_axis_tuser  ( m_axis_tuser  ),
	.m_axis_tvalid ( m_axis_tvalid ),
	.m_axis_tready ( m_axis_tready ),
	.m_axis_tlast  ( m_axis_tlast  ),
	
	// Slave Stream Ports (interface to RX queues)
	.s_axis_tdata  ( s_axis_tdata  ),
	.s_axis_tkeep  ( s_axis_tkeep  ),
	.s_axis_tuser  ( s_axis_tuser  ),
	.s_axis_tvalid ( s_axis_tvalid ),
	.s_axis_tready ( s_axis_tready ),
	.s_axis_tlast  ( s_axis_tlast  ),

	// Slave AXI Ports
	.S_AXI_ACLK    (),
	.S_AXI_ARESETN (),
	.S_AXI_AWADDR  (),
	.S_AXI_AWVALID (),
	.S_AXI_WDATA   (),
	.S_AXI_WSTRB   (),
	.S_AXI_WVALID  (),
	.S_AXI_BREADY  (),
	.S_AXI_ARADDR  (),
	.S_AXI_ARVALID (),
	.S_AXI_RREADY  (),
	.S_AXI_ARREADY (),
	.S_AXI_RDATA   (),
	.S_AXI_RRESP   (),
	.S_AXI_RVALID  (),
	.S_AXI_WREADY  (),
	.S_AXI_BRESP   (),
	.S_AXI_BVALID  (),
	.S_AXI_AWREADY () 
);

reg [256+128+32+4+4-1:0] rom [0:500];
reg [22:0]counter = 23'd0;
reg reset_semi;
reg [2:0] dummy0, dummy1;

assign m_axis_tready = 1;

always @ (posedge nf_clk_i) begin
	if (!sys_rst_n) begin
		counter       <= 0;
		s_axis_tdata  <= 0;
		s_axis_tkeep  <= 0;
		s_axis_tuser  <= 0;
		s_axis_tlast  <= 0;
		s_axis_tvalid <= 0;
	end else begin
		{s_axis_tdata, s_axis_tkeep, s_axis_tuser, dummy0, s_axis_tvalid, dummy1, s_axis_tlast} <= rom[counter];
		if (s_axis_tready)
			counter	<= counter + 23'd1;
	end
end

initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_sim);
	$readmemh("../../../test.rom", rom);

	$display("Simulation begins.");
	$display("================================================");
	
	waitclk(60000);

	$display("================================================");
	$display("Result: %d", u_wombat.return_value_reg);
	$display("Simulation finishes.");

	$finish;
end

endmodule
