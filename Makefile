VERILATOR ?= verilator
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj_dir
TOP := single_cycle_cpu
RTL := rtl/common/alu.sv rtl/common/decoder.sv rtl/common/regfile.sv \
	rtl/single_cycle/single_cycle_cpu.sv
TESTBENCH := sim/verilator/tb_single_cycle.cpp sim/verilator/rv64i_tests.cpp
SIM := $(OBJ_DIR)/V$(TOP)

PIPELINE_OBJ_DIR := $(BUILD_DIR)/pipeline_obj_dir
PIPELINE_RTL := rtl/common/alu.sv rtl/common/decoder.sv rtl/common/regfile.sv \
	rtl/pipeline/pipeline_execute.sv rtl/pipeline/pipeline_writeback.sv \
	rtl/pipeline/pipeline_memory_port.sv rtl/pipeline/pipeline_hazard.sv \
	rtl/pipeline/pipeline_cpu.sv
PIPELINE_TESTBENCH := sim/verilator/tb_pipeline.cpp sim/verilator/rv64i_tests.cpp
PIPELINE_SIM := $(PIPELINE_OBJ_DIR)/Vpipeline_cpu

.PHONY: help build lint test pipeline-build pipeline-lint pipeline-test clean

help:
	@echo "Targets:"
	@echo "  make build  Build the Verilator simulator"
	@echo "  make lint   Lint the current RTL"
	@echo "  make test   Build and run the RV64I single-cycle regression"
	@echo "  make pipeline-lint  Lint the five-stage RTL"
	@echo "  make pipeline-test  Build and run the five-stage regression"
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

pipeline-build: $(PIPELINE_SIM)

$(PIPELINE_SIM): $(PIPELINE_RTL) $(PIPELINE_TESTBENCH)
	mkdir -p $(PIPELINE_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module pipeline_cpu \
		--Mdir $(PIPELINE_OBJ_DIR) $(PIPELINE_RTL) $(PIPELINE_TESTBENCH)

pipeline-lint:
	$(VERILATOR) --lint-only --Wall $(PIPELINE_RTL)

pipeline-test: pipeline-build
	$(PIPELINE_SIM)

clean:
	rm -rf $(BUILD_DIR)
