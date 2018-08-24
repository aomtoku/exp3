###################################################################
#  Makefile for simulation                                        #
#  All rights reserved (C) 2017 Yuta Tokusashi                    #
###################################################################

proj = "nfsume-dram"

sim_top = app_tb
outdir = build

# Xilinx sources and top module
RTL_SRC := ../hdl/verilog/wombat.v\
           ../hdl/verilog/wombat_cpu_regs.v\
           ../hdl/verilog/asfifo.v\
           ../hdl/verilog/graycounter.v\
           ../hdl/verilog/mmcm_wrapper.v\
           ../hdl/verilog/prbs.v\
		   ../hdl/verilog/exp3_fallthrough_small_fifo.v\
		   ../hdl/verilog/exp3_small_fifo.v\
           tb_sim.v\
           /opt/Xilinx/Vivado/2016.4/data/verilog/src/glbl.v

all: xsim

xsim:
	test -e $(outdir) || mkdir $(outdir)
	vivado -mode batch -source sim.tcl -log $(outdir)/createprj_log.txt -nojournal -tclargs "$(RTL_SRC)" "$(IP_SRC)"

xsim-gui:
	test -e $(outdir) || mkdir $(outdir)
	vivado -mode gui -source sim.tcl -log $(outdir)/createprj_log.txt -nojournal -tclargs "$(RTL_SRC)" "$(IP_SRC)"

wave:
	gtkwave test.vcd &

questa: 
	vsim -64 -c -do questa_sim.do

questa-gui:
	vsim -64 -do questa_sim.do -gui

clean:
	rm -f wave.vcd vsim.wlf transcript
	rm -rf obj_dir work
	rm -rf vivado* .Xil
	rm -f test.vcd
	rm -rf wombat.*
	rm -rf build
	rm -rf synth

distclean:
	rm -rf dnskv.*

