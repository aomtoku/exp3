
vlib work 
vlib work/floating_point_v7_1_3
vlib work/xbip_utils_v3_0_7
vlib work/axi_utils_v2_0_3
vlib work/mult_gen_v12_0_12

#Map the required libraries here#
vmap unisims_ver /home2/tokusasi/local/opt/unisims_ver
vmap unisim      /home2/tokusasi/local/opt/unisim
vmap unimacro    /home2/tokusasi/local/opt/unimacro_ver
vmap secureip    /home2/tokusasi/local/opt/secureip
vmap xilinxcorelib /home2/tokusasi/local/opt/xilinxcorelib
vmap xilinxcorelib_ver /home2/tokusasi/local/opt/xilinxcorelib_ver
vmap floating_point_v7_1_3 work/floating_point_v7_1_3
vmap xbip_utils_v3_0_7 work/xbip_utils_v3_0_7
vmap axi_utils_v2_0_3 work/axi_utils_v2_0_3
vmap mult_gen_v12_0_12 work/mult_gen_v12_0_12

#Compile all modules#

# Compile files in sim folder (excluding model parameter file)
vlog +define+SIMULATION_DEBUG ../hdl/verilog/sdar.v
vlog ../hdl/verilog/asfifo.v
vlog ../hdl/verilog/graycounter.v
vlog ../hdl/verilog/sdar_cpu_regs.v
vlog ../hdl/hls/Block_proc25.v
vlog ../hdl/hls/changefinder_dadd_64ns_64nslbW.v
vlog ../hdl/hls/changefinder_ddiv_64ns_64nshbi.v
vlog ../hdl/hls/changefinder_dexp_64ns_64nskbM.v
vlog ../hdl/hls/changefinder_dlog_64ns_64nsjbC.v
vlog ../hdl/hls/changefinder_dmul_64ns_64nsg8j.v
vlog ../hdl/hls/changefinder_dsqrt_64ns_64nibs.v
vlog ../hdl/hls/changefinder_fadd_32ns_32nsmb6.v
vlog ../hdl/hls/changefinder_faddfsub_32ns_cud.v
vlog ../hdl/hls/changefinder_fdiv_32ns_32nseOg.v
vlog ../hdl/hls/changefinder_fmul_32ns_32nsdEe.v
vlog ../hdl/hls/changefinder_forgetability_ncg.v
vlog ../hdl/hls/changefinder_forgetability_ocq.v
vlog ../hdl/hls/changefinder_fpext_32ns_64_1.v  
vlog ../hdl/hls/changefinder_fptrunc_64ns_3fYi.v
vlog ../hdl/hls/changefinder_fsub_32ns_32nsbkb.v
vlog ../hdl/hls/changefinder_input_channel.v    
vlog ../hdl/hls/changefinder_mux_32_32_1.v
vlog ../hdl/hls/changefinder_p_channel3.v
vlog ../hdl/hls/changefinder_p_channel.v
vlog ../hdl/hls/changefinder_r_loc_channel1.v
vlog ../hdl/hls/changefinder_r_loc_channel.v
vlog ../hdl/hls/changefinder_sitofp_32ns_32_1.v
vlog ../hdl/hls/changefinder_smoothscore_chpcA.v
vlog ../hdl/hls/changefinder_srem_3ns_3ns_3_7.v
vlog ../hdl/hls/changefinder.v
vlog ../hdl/hls/est_value_1.v
vlog ../hdl/hls/est_value_2.v
vlog ../hdl/hls/log_func.v
vlog ../hdl/hls/sdar1.v
vlog ../hdl/hls/sdar2.v
vlog ../hdl/hls/smoothing1.v
vlog ../hdl/hls/smoothing2.v
vlog ../hdl/hls/start_for_sdar1_U0.v
vlog tb_sim.v
#vlog /opt/Xilinx/Vivado/2016.4/data/verilog/src/glbl.v

#vcom -64 -work xbip_utils_v3_0_7 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/xbip_utils_v3_0_vh_rfs.vhd
##vcom -64 -work xbip_utils_v3_0_7 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/axi_utils_v2_0_vh_rfs.vhd 
#vcom -64 -work axi_utils_v2_0_3 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/axi_utils_v2_0_vh_rfs.vhd 
#vcom -64 -work mult_gen_v12_0_12 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/mult_gen_v12_0_vh_rfs.vhd 
#vcom -64 -work floating_point_v7_1_3 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/floating_point_v7_1_vh_rfs.vhd 
#vcom -64 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/xbip_bram18k_v3_0_vh_rfs.vhd 
#vcom -64 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/xbip_dsp48_addsub_v3_0_vh_rfs.vhd 
#vcom -64 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/xbip_dsp48_multadd_v3_0_vh_rfs.vhd 
#vcom -64 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/xbip_dsp48_wrapper_v3_0_vh_rfs.vhd 
#vcom -64 ./synth/changefinder_ap_dadd_2_full_dsp_64/hdl/xbip_pipe_v3_0_vh_rfs.vhd 
#vcom -64 ./synth/changefinder_ap_ddiv_11_no_dsp_64/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_dexp_6_full_dsp_64/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_dlog_11_full_dsp_64/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_dmul_2_max_dsp_64/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_dsqrt_10_no_dsp_64/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_fadd_1_full_dsp_32/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_faddfsub_1_full_dsp_32/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_fdiv_4_no_dsp_32/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_fmul_0_max_dsp_32/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_fpext_0_no_dsp_32/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_fptrunc_0_no_dsp_64/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_fsub_1_full_dsp_32/hdl/*.vhd
#vcom -64 ./synth/changefinder_ap_sitofp_0_no_dsp_32/hdl/*.vhd

vcom -64 -work xilinxcorelib ./synth/changefinder_ap_dadd_2_full_dsp_64/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_ddiv_11_no_dsp_64/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_dexp_6_full_dsp_64/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_dlog_11_full_dsp_64/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_dmul_2_max_dsp_64/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_dsqrt_10_no_dsp_64/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_fadd_1_full_dsp_32/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_faddfsub_1_full_dsp_32/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_fdiv_4_no_dsp_32/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_fmul_0_max_dsp_32/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_fpext_0_no_dsp_32/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_fptrunc_0_no_dsp_64/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_fsub_1_full_dsp_32/sim/*.vhd
vcom -64 -work xilinxcorelib ./synth/changefinder_ap_sitofp_0_no_dsp_32/sim/*.vhd

# Load the design. Use required libraries.
vsim -t fs -novopt +notimingchecks -wlfopt -L unisims_ver -L secureip -L xilinxcorelib work.tb_sim glbl
#vsim -t fs -novopt +notimingchecks -wlfopt  work.tb_sim 

onerror {resume}

# View sim_tb_top signals in waveform#
add wave sim:/tb_sim/*
# Change radix to Hexadecimal#
radix hex

# In case calibration fails to complete, choose the run time and then 
# stop

run -all
stop
