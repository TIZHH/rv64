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
	@echo "  make build             Build the legacy single-cycle Verilator model"
	@echo "  make lint              Lint the legacy single-cycle RTL"
	@echo "  make test              Run the legacy full RV64I regression"
	@echo "  make branch-unit-test  Test branch_unit in isolation"
	@echo "  make modular-lint      Lint the modular core and file-backed memories"
	@echo "  make modular-test      Run the full RV64I regression on modular_core"
	@echo "  make file-memory-test  Boot from instruction.hex/data.hex images"
	@echo "  make pipeline-lint     Lint the five-stage pipeline RTL"
	@echo "  make pipeline-test     Run the full RV64I regression on the pipeline"
	@echo "  make clean             Remove generated Verilator build output"

# Legacy single-cycle CPU: external C++ testbench supplies instruction words
# and models byte-addressed data memory. This is the original reference top.
build: $(SIM)

$(SIM): $(RTL) $(TESTBENCH)
	mkdir -p $(OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module $(TOP) \
		--Mdir $(OBJ_DIR) $(RTL) $(TESTBENCH)

# Legacy single-cycle lint only; no C++ testbench is compiled here.
lint:
	$(VERILATOR) --lint-only --Wall $(RTL)

# Full legacy single-cycle architecture regression. The cases are defined in
# sim/verilator/rv64i_tests.cpp and cover ALU, control flow, memory, W ops,
# and illegal-instruction visibility.
test: build
	$(SIM)

BRANCH_UNIT_OBJ_DIR := $(BUILD_DIR)/branch_unit_obj_dir
BRANCH_UNIT_SIM := $(BRANCH_UNIT_OBJ_DIR)/Vbranch_unit

# Isolated combinational unit test: 13 truth-table cases for BEQ/BNE/BLT/BGE/
# BLTU/BGEU, including signed-vs-unsigned comparisons and unsupported types.
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

# Modular single-cycle core build. This excludes the file-backed memory wrapper
# so that the core can be tested with the same external-memory regression.
modular-build: $(MODULAR_CORE_SIM)

$(MODULAR_CORE_SIM): $(MODULAR_CORE_RTL) $(MODULAR_CORE_TESTBENCH)
	mkdir -p $(MODULAR_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module single_cycle_core \
		--Mdir $(MODULAR_OBJ_DIR) $(MODULAR_CORE_RTL) $(MODULAR_CORE_TESTBENCH)

# Lint the modular core, its split datapath/control modules, and both memories.
modular-lint:
	$(VERILATOR) --lint-only --Wall $(MODULAR_SYSTEM_RTL)

# Full legacy RV64I test table run against single_cycle_core after the port and
# datapath modularization. This checks architectural behavior, not just wiring.
modular-test: modular-build
	$(MODULAR_CORE_SIM)

# File-backed integration smoke test. The CPU fetches from instruction.hex,
# loads a value from data.hex, performs ADDI, and stores the result at 0x100.
file-memory-test: $(MODULAR_SYSTEM_SIM)
	$(MODULAR_SYSTEM_SIM)

$(MODULAR_SYSTEM_SIM): $(MODULAR_SYSTEM_RTL) $(MODULAR_SYSTEM_TESTBENCH) \
	sim/images/instruction.hex sim/images/data.hex
	mkdir -p $(MODULAR_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module single_cycle_file_system \
		--Mdir $(MODULAR_OBJ_DIR) $(MODULAR_SYSTEM_RTL) $(MODULAR_SYSTEM_TESTBENCH)

# Five-stage pipeline build and regression use the same architectural test table
# as the two single-cycle implementations for direct behavior comparison.
pipeline-build: $(PIPELINE_SIM)

$(PIPELINE_SIM): $(PIPELINE_RTL) $(PIPELINE_TESTBENCH)
	mkdir -p $(PIPELINE_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module pipeline_cpu \
		--Mdir $(PIPELINE_OBJ_DIR) $(PIPELINE_RTL) $(PIPELINE_TESTBENCH)

# Lint the IF/ID/EX/MEM/WB pipeline and hazard/forwarding modules.
pipeline-lint:
	$(VERILATOR) --lint-only --Wall $(PIPELINE_RTL)

# Full RV64I architectural regression on the pipelined implementation.
pipeline-test: pipeline-build
	$(PIPELINE_SIM)

# Remove all generated Verilator models and object files.
clean:
	rm -rf $(BUILD_DIR)
