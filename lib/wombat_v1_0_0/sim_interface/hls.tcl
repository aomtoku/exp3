###########################################################
#  Vivado HLS 
#  Copyright (c) 2016 Yuta Tokusashi. All rights reserved
###########################################################

set prj "app"
set device xc7vx690tffg1761-3
## Target Clock Period (ns) / ?MHz
set clock_period 5.0

set src [lindex $argv 3]
set top [lindex $argv 4]
set mode [lindex $argv 5]
set tb  [lindex $argv 6]

### Project file initilizing ###
open_project -reset ${prj}
set_top ${top}
add_files ${src}
#foreach cfile ${src} {
#	if {[string match *.c ${cfile}]} {
#		add_files ${cfile}
#	}
#}

foreach tfile ${tb} {
	if {[string match *.cpp ${tfile}]} {
		add_files -tb ${tfile}
	}
}

### Setting boards parameter ###
open_solution -reset "solution1"
set_part ${device}
create_clock -period ${clock_period} -name default

source "./directive.tcl"

### HLS Design to RTL ###

if {[string match "synth" ${mode}]} {
	csynth_design
} elseif {[string match "csim" ${mode}]} {
	csim_design
} elseif {[string match "cosim" ${mode}]} {
	# TBD
	csynth_design
	cosim_design
} elseif {[string match "export_ip" ${mode}]} {
	# TBD
	export_design -evaluate verilog -format ip_catalog
}

exit
