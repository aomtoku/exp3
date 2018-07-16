`timescale 1ns / 1ps
/******************************************************************
 * MMCM wrapper module                                            *
 * All rights reserved (C) 2017 Yuta Tokusashi                    *
 *****************************************************************/
module mmcm_wrapper (
	input  wire inclk,
	input  wire inrst,
	
	output wire dout_clk,
	output wire dout_rst

);

wire clk_mmcme2;
wire clk_fbin; 
wire clk_fbout; 
wire clk_locked;

// CLK0 125MHz (160MHz x 5 / 6.4)
//
//
MMCME2_BASE #(
	.BANDWIDTH("OPTIMIZED"),
	.CLKFBOUT_MULT_F(31.25),
	.CLKFBOUT_PHASE(0.0),
	.CLKIN1_PERIOD(12.5),
	.CLKOUT0_DIVIDE_F(10),
	.CLKOUT1_DIVIDE(5),
	.CLKOUT2_DIVIDE(5),
	.CLKOUT3_DIVIDE(5),
	.CLKOUT4_DIVIDE(5),
	.CLKOUT5_DIVIDE(5),
	.CLKOUT6_DIVIDE(5),
	.CLKOUT0_DUTY_CYCLE(0.5),
	.CLKOUT1_DUTY_CYCLE(0.5),
	.CLKOUT2_DUTY_CYCLE(0.5),
	.CLKOUT3_DUTY_CYCLE(0.5),
	.CLKOUT4_DUTY_CYCLE(0.5),
	.CLKOUT5_DUTY_CYCLE(0.5),
	.CLKOUT6_DUTY_CYCLE(0.5),
	.CLKOUT0_PHASE(0.0),
	.CLKOUT1_PHASE(0.0),
	.CLKOUT2_PHASE(0.0),
	.CLKOUT3_PHASE(0.0),
	.CLKOUT4_PHASE(0.0),
	.CLKOUT5_PHASE(0.0),
	.CLKOUT6_PHASE(0.0),
	.CLKOUT4_CASCADE("FALSE"),
	.DIVCLK_DIVIDE(2),
	.REF_JITTER1(0.0),
	.STARTUP_WAIT("FALSE")
) u_MMCME2_BASE (
	.CLKOUT0(clk_mmcme2),
	.CLKOUT0B(),
	.CLKOUT1(),
	.CLKOUT1B(),
	.CLKOUT2(),
	.CLKOUT2B(),
	.CLKOUT3(),
	.CLKOUT3B(),
	.CLKOUT4(),
	.CLKOUT5(),
	.CLKOUT6(),
	.CLKFBOUT(clk_fbout),
	.CLKFBOUTB(),
	.LOCKED(clk_locked),
	.CLKIN1(inclk),
	.PWRDWN(1'b0),
	.RST(inrst),
	.CLKFBIN(clk_fbin)
);

BUFG BUFG_FB (
  .I(clk_fbout),
  .O(clk_fbin)
);

BUFG BUFG_CLK0 (
  .I(clk_mmcme2),
  .O(dout_clk)
);


assign dout_rst = !clk_locked;

endmodule
