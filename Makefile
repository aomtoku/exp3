PWD := $(shell pwd)
TARGET_DIR := $(SUME_FOLDER)
LIB_DIR := $(SUME_FOLDER)/lib/hw/std/cores

install:
	ln -s $(PWD)/lib/wombat_v1_0_0 $(LIB_DIR)/
	cp -r $(PWD)/inference_server $(TARGET_DIR)/contrib-projects/

clean:
	rm -r $(LIB_DIR)/wombat_v1_0_0
	rm -r $(TARGET_DIR)/contrib-projects/inference_server
