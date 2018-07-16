#!/bin/bash

for tcl in `ls ./*.tcl`;
do
	echo $tcl
	sed -i -e 's/-dir ./synth/g' $tcl
done
