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

.PHONY: help build lint test branch-unit-test modular-build modular-lint modular-test file-memory-test \
	pipeline-build pipeline-lint pipeline-test clean

help:
	@echo "Targets:"
	@echo "  make build  Build the Verilator simulator"
	@echo "  make lint   Lint the current RTL"
	@echo "  make test   Build and run the RV64I single-cycle regression"
	@echo "  make branch-unit-test  Run the isolated branch comparator test"
	@echo "  make modular-lint  Lint the modular single-cycle RTL"
	@echo "  make modular-test  Run the modular single-cycle regression"
	@echo "  make file-memory-test  Run the file-backed memory smoke test"
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

BRANCH_UNIT_OBJ_DIR := $(BUILD_DIR)/branch_unit_obj_dir
BRANCH_UNIT_SIM := $(BRANCH_UNIT_OBJ_DIR)/Vbranch_unit

branch-unit-test: $(BRANCH_UNIT_SIM)
	$(BRANCH_UNIT_SIM)

$(BRANCH_UNIT_SIM): rtl/single_cycle_modular/branch_unit.sv \
	sim/verilator/tb_branch_unit.cpp
	mkdir -p $(BRANCH_UNIT_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module branch_unit \
		--Mdir $(BRANCH_UNIT_OBJ_DIR) $^

MODULAR_OBJ_DIR := $(BUILD_DIR)/modular_obj_dir
MODULAR_CORE_RTL := rtl/common/alu.sv rtl/common/decoder.sv rtl/common/regfile.sv \
	rtl/single_cycle_modular/branch_unit.sv rtl/single_cycle_modular/memory_access.sv \
	rtl/single_cycle_modular/next_pc_logic.sv rtl/single_cycle_modular/pc_register.sv \
	rtl/single_cycle_modular/writeback_mux.sv rtl/single_cycle_modular/single_cycle_core.sv
MODULAR_CORE_TESTBENCH := sim/verilator/tb_single_cycle_modular.cpp sim/verilator/rv64i_tests.cpp
MODULAR_CORE_SIM := $(MODULAR_OBJ_DIR)/Vsingle_cycle_core

MODULAR_SYSTEM_RTL := $(MODULAR_CORE_RTL) rtl/memory/instruction_memory.sv \
	rtl/memory/data_memory.sv rtl/single_cycle_modular/single_cycle_file_system.sv
MODULAR_SYSTEM_TESTBENCH := sim/verilator/tb_single_cycle_files.cpp
MODULAR_SYSTEM_SIM := $(MODULAR_OBJ_DIR)/Vsingle_cycle_file_system

modular-build: $(MODULAR_CORE_SIM)

$(MODULAR_CORE_SIM): $(MODULAR_CORE_RTL) $(MODULAR_CORE_TESTBENCH)
	mkdir -p $(MODULAR_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module single_cycle_core \
		--Mdir $(MODULAR_OBJ_DIR) $(MODULAR_CORE_RTL) $(MODULAR_CORE_TESTBENCH)

modular-lint:
	$(VERILATOR) --lint-only --Wall $(MODULAR_SYSTEM_RTL)

modular-test: modular-build
	$(MODULAR_CORE_SIM)

file-memory-test: $(MODULAR_SYSTEM_SIM)
	$(MODULAR_SYSTEM_SIM)

$(MODULAR_SYSTEM_SIM): $(MODULAR_SYSTEM_RTL) $(MODULAR_SYSTEM_TESTBENCH) \
	sim/images/instruction.hex sim/images/data.hex
	mkdir -p $(MODULAR_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module single_cycle_file_system \
		--Mdir $(MODULAR_OBJ_DIR) $(MODULAR_SYSTEM_RTL) $(MODULAR_SYSTEM_TESTBENCH)

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
