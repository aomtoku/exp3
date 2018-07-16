#!/bin/sh

for tcl in `ls ./*.tcl`;
do
	echo $tcl
	sed -i -e 's/create_ip -name/create_ip -dir .\/synth -name/g' $tcl
done
