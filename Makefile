VERILATOR ?= verilator
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj_dir
TOP := single_cycle_cpu
RTL := rtl/single_cycle/single_cycle_cpu.sv
TESTBENCH := sim/verilator/tb_single_cycle.cpp
SIM := $(OBJ_DIR)/V$(TOP)

.PHONY: help build lint test clean

help:
	@echo "Targets:"
	@echo "  make build  Build the Verilator simulator"
	@echo "  make lint   Lint the current RTL"
	@echo "  make test   Build and run the reset/clock smoke test"
	@echo "  make clean  Remove generated build output"

build: $(SIM)

$(SIM): $(RTL) $(TESTBENCH)
	mkdir -p $(OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module $(TOP) \
		--Mdir $(OBJ_DIR) $(RTL) $(TESTBENCH)

lint:
	$(VERILATOR) --lint-only --Wall $(RTL)

test: build
	$(SIM)

clean:
	rm -rf $(BUILD_DIR)
