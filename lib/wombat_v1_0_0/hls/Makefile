
SRC := ../src/predict_exp3.cpp
TB  := ../src/exp3_test.cpp
TOP_FUNC := predict

all: clean export

gui:
	vivado_hls -f hls.tcl -tclargs "$(SRC)" "$(TOP_FUNC)" "synth"

export:
	vivado_hls -i -f hls.tcl -tclargs "$(SRC)" "$(TOP_FUNC)" "synth" "$(TB)"
	cat app/solution1/syn/report/$(TOP_FUNC)_csynth.rpt

update:
	rm -f ../hdl/hls/*.v
	rm -f ../scripts/*.tcl
	cp app/solution1/syn/verilog/*.v ../hdl/hls/
	cp app/solution1/syn/verilog/*.tcl ../scripts/
	cd ../scripts/ && bash update.sh

csim:
	vivado_hls -i -f hls.tcl -tclargs "$(SRC)" "$(TOP_FUNC)" "csim" "$(TB)"

cosim:
	vivado_hls -i -f hls.tcl -tclargs "$(SRC)" "$(TOP_FUNC)" "cosim" "$(TB)"

report: app/solution1/syn/report/$(TOP_FUNC)_csynth.rpt
	cat app/solution1/syn/report/$(TOP_FUNC)_csynth.rpt
	

.PHONY: clean
clean:
	@rm -rf app
	@rm -f vivado_hls.log
