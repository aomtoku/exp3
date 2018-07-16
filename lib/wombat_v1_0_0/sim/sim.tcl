###################################################################
#  Simulation TCL for xsim                                        #
#  All rights reserved (C) 2017 Yuta Tokusashi                    #
###################################################################

set RTL_SRC [lindex $argv 0]
puts "INFO: RTL_SRC"
puts ${RTL_SRC}
set IP_SRC [lindex $argv 1]
puts "INFO: IP_SRC"
puts ${IP_SRC}
set XDC_SRC [lindex $argv 2]
puts "INFO: XDC_SRC"
puts ${XDC_SRC}


#set design top
set device xc7vx690t-3-ffg1761
set outdir build
set hls_verilog "../hdl/hls"
set hls_tcl "../scripts"
set synth_dir "./synth"

# Project Settings
create_project -name sdar -force -part ${device}

set_property top tb_sim [get_filesets sim_1]
set_property target_language Verilog [current_project]
set_property default_lib "xil_defaultlib" [current_project]
set_property verilog_define { {DEBUG=1} {SIMULATION_DEBUG=1} {DRAM_SUPPORT=1} } [get_filesets sim_1]
set_property "simulator_language" "Mixed" [current_project]


update_ip_catalog -rebuild

puts "INFO: Import RTL Sources ..."
foreach file $RTL_SRC {
	# verilog
	if {[string match *.v $file]} {
		puts "INFO: Import $file (Verilog)"
		read_verilog $file
	} elseif {[string match *.sv $file]} {
		puts "INFO: Import $file (SystemVerilog)"
		read_verilog -sv $file
	} elseif {[string match *.vhd $file] || [string match *.vhdl $file]} {
		puts "INFO: Import $file (VHDL)"
		read_vhdl $file
	} else {
		puts "INFO: Unsupported File $file"    
	}
}

set vfiles [exec ls ${hls_verilog}]
foreach file ${vfiles} {
	if {[string match *.v ${file}]} {
		puts "INFO: import ${hls_verilog}/${file} (Verilog HDL)"
		read_verilog "./${hls_verilog}/${file}"
	}
}

puts "INFO: Import IP Sources ..."
foreach file $IP_SRC {
	if {[string match *.xci $file]} {
		puts "INFO: Import IP $file"
		read_ip $file
		synth_ip -force [get_files $file]
	} elseif {[string match *.dcp $file]} {
		read_checkpoint $file
	} else {
		puts "INFO: Unsupported File $file" 
	}
}

if { [file exists $synth_dir] == 0 } then {
	puts "synth is generated."
	file mkdir $synth_dir 
} 

set tcls [exec ls ${hls_tcl}]
foreach file ${tcls} {
	if {[string match *.tcl $file]} {
		puts "INFO: import ${hls_tcl}/${file} (IP catalog)"
		source "./${hls_tcl}/${file}"
	}
}


launch_simulation

#run 10 us
run all
