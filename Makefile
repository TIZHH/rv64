VERILATOR ?= verilator
BUILD_DIR := build

.PHONY: help lint test clean \
	branch-unit-model branch-unit-test \
	pc-register-model pc-register-test \
	next-pc-logic-model next-pc-logic-test \
	single-cycle-core-model single-cycle-core-test \
	single-cycle-file-system-model single-cycle-file-system-test

help:
	@echo "可用目标:"
	@echo "  make lint                           检查模块化单周期和文件内存 RTL"
	@echo "  make test                           运行下面列出的全部 Verilator 测试"
	@echo "  make branch-unit-model              生成 branch_unit Verilator 模型"
	@echo "  make branch-unit-test               测试六种 RV64I 分支比较"
	@echo "  make pc-register-model              生成 pc_register Verilator 模型"
	@echo "  make pc-register-test               测试 PC 复位和时钟更新"
	@echo "  make next-pc-logic-model             生成 next_pc_logic Verilator 模型"
	@echo "  make next-pc-logic-test              测试顺序、分支、JAL 和 JALR 下一 PC"
	@echo "  make single-cycle-core-model         生成模块化单周期核心模型"
	@echo "  make single-cycle-core-test          运行模块化单周期 RV64I 回归测试"
	@echo "  make single-cycle-file-system-model  生成文件内存系统模型"
	@echo "  make single-cycle-file-system-test   运行指令/数据镜像启动测试"
	@echo "  make clean                           删除生成的 Verilator 构建文件"

# ------------------------------
# branch_unit：组合逻辑分支比较模块。
BRANCH_UNIT_RTL := rtl/single_cycle_modular/branch_unit.sv
BRANCH_UNIT_TESTBENCH := sim/verilator/tb_branch_unit.cpp
BRANCH_UNIT_OBJ_DIR := $(BUILD_DIR)/branch_unit_obj_dir
BRANCH_UNIT_SIM := $(BRANCH_UNIT_OBJ_DIR)/Vbranch_unit

branch-unit-model: $(BRANCH_UNIT_RTL)
	mkdir -p $(BRANCH_UNIT_OBJ_DIR)
	$(VERILATOR) --cc \
		--top-module branch_unit \
		--Mdir $(BRANCH_UNIT_OBJ_DIR) \
		$^

branch-unit-test: $(BRANCH_UNIT_SIM)
	$(BRANCH_UNIT_SIM)

$(BRANCH_UNIT_SIM): $(BRANCH_UNIT_RTL) $(BRANCH_UNIT_TESTBENCH)
	mkdir -p $(BRANCH_UNIT_OBJ_DIR)
	$(VERILATOR) --cc --exe --build \
		--top-module branch_unit \
		--Mdir $(BRANCH_UNIT_OBJ_DIR) \
		$^

# ------------------------------
# pc_register：带同步复位的 PC 时序寄存器。
PC_REGISTER_RTL := rtl/single_cycle_modular/pc_register.sv
PC_REGISTER_TESTBENCH := sim/verilator/tb_pc_register.cpp
PC_REGISTER_OBJ_DIR := $(BUILD_DIR)/pc_register_obj_dir
PC_REGISTER_SIM := $(PC_REGISTER_OBJ_DIR)/Vpc_register

pc-register-model: $(PC_REGISTER_RTL)
	mkdir -p $(PC_REGISTER_OBJ_DIR)
	$(VERILATOR) --cc \
		--top-module pc_register \
		--Mdir $(PC_REGISTER_OBJ_DIR) \
		$^

pc-register-test: $(PC_REGISTER_SIM)
	$(PC_REGISTER_SIM)

$(PC_REGISTER_SIM): $(PC_REGISTER_RTL) $(PC_REGISTER_TESTBENCH)
	mkdir -p $(PC_REGISTER_OBJ_DIR)
	$(VERILATOR) --cc --exe --build \
		--top-module pc_register \
		--Mdir $(PC_REGISTER_OBJ_DIR) \
		$^

# ------------------------------
# next_pc_logic：顺序、分支、JAL 和 JALR 下一 PC 选择。
NEXT_PC_LOGIC_RTL := rtl/single_cycle_modular/next_pc_logic.sv
NEXT_PC_LOGIC_TESTBENCH := sim/verilator/tb_next_pc_logic.cpp
NEXT_PC_LOGIC_OBJ_DIR := $(BUILD_DIR)/next_pc_logic_obj_dir
NEXT_PC_LOGIC_SIM := $(NEXT_PC_LOGIC_OBJ_DIR)/Vnext_pc_logic

next-pc-logic-model: $(NEXT_PC_LOGIC_RTL)
	mkdir -p $(NEXT_PC_LOGIC_OBJ_DIR)
	$(VERILATOR) --cc \
		--top-module next_pc_logic \
		--Mdir $(NEXT_PC_LOGIC_OBJ_DIR) \
		$^

next-pc-logic-test: $(NEXT_PC_LOGIC_SIM)
	$(NEXT_PC_LOGIC_SIM)

$(NEXT_PC_LOGIC_SIM): $(NEXT_PC_LOGIC_RTL) $(NEXT_PC_LOGIC_TESTBENCH)
	mkdir -p $(NEXT_PC_LOGIC_OBJ_DIR)
	$(VERILATOR) --cc --exe --build \
		--top-module next_pc_logic \
		--Mdir $(NEXT_PC_LOGIC_OBJ_DIR) \
		$^

# ------------------------------
# single_cycle_core：模块化单周期 RV64I 核心，内存由 C++ 测试台模拟。
SINGLE_CYCLE_CORE_RTL := rtl/common/alu.sv rtl/common/decoder.sv rtl/common/regfile.sv \
	rtl/single_cycle_modular/branch_unit.sv rtl/single_cycle_modular/memory_access.sv \
	rtl/single_cycle_modular/next_pc_logic.sv rtl/single_cycle_modular/pc_register.sv \
	rtl/single_cycle_modular/writeback_mux.sv rtl/single_cycle_modular/single_cycle_core.sv
SINGLE_CYCLE_CORE_TESTBENCH := sim/verilator/tb_single_cycle_modular.cpp
SINGLE_CYCLE_CORE_OBJ_DIR := $(BUILD_DIR)/single_cycle_core_obj_dir
SINGLE_CYCLE_CORE_SIM := $(SINGLE_CYCLE_CORE_OBJ_DIR)/Vsingle_cycle_core

single-cycle-core-model: $(SINGLE_CYCLE_CORE_RTL)
	mkdir -p $(SINGLE_CYCLE_CORE_OBJ_DIR)
	$(VERILATOR) --cc \
		--top-module single_cycle_core \
		--Mdir $(SINGLE_CYCLE_CORE_OBJ_DIR) \
		$^

single-cycle-core-test: $(SINGLE_CYCLE_CORE_SIM)
	$(SINGLE_CYCLE_CORE_SIM)

$(SINGLE_CYCLE_CORE_SIM): $(SINGLE_CYCLE_CORE_RTL) $(SINGLE_CYCLE_CORE_TESTBENCH)
	mkdir -p $(SINGLE_CYCLE_CORE_OBJ_DIR)
	$(VERILATOR) --cc --exe --build \
		--top-module single_cycle_core \
		--Mdir $(SINGLE_CYCLE_CORE_OBJ_DIR) \
		$^

# ------------------------------
# single_cycle_file_system：核心连接独立的文件初始化指令和数据内存。
SINGLE_CYCLE_FILE_SYSTEM_RTL := $(SINGLE_CYCLE_CORE_RTL) \
	rtl/memory/instruction_memory.sv rtl/memory/data_memory.sv \
	rtl/single_cycle_modular/single_cycle_file_system.sv
SINGLE_CYCLE_FILE_SYSTEM_TESTBENCH := sim/verilator/tb_single_cycle_files.cpp
SINGLE_CYCLE_FILE_SYSTEM_IMAGES := sim/images/instruction.hex sim/images/data.hex
SINGLE_CYCLE_FILE_SYSTEM_OBJ_DIR := $(BUILD_DIR)/single_cycle_file_system_obj_dir
SINGLE_CYCLE_FILE_SYSTEM_SIM := $(SINGLE_CYCLE_FILE_SYSTEM_OBJ_DIR)/Vsingle_cycle_file_system

single-cycle-file-system-model: $(SINGLE_CYCLE_FILE_SYSTEM_RTL)
	mkdir -p $(SINGLE_CYCLE_FILE_SYSTEM_OBJ_DIR)
	$(VERILATOR) --cc \
		--top-module single_cycle_file_system \
		--Mdir $(SINGLE_CYCLE_FILE_SYSTEM_OBJ_DIR) \
		$^

single-cycle-file-system-test: $(SINGLE_CYCLE_FILE_SYSTEM_SIM)
	$(SINGLE_CYCLE_FILE_SYSTEM_SIM)

$(SINGLE_CYCLE_FILE_SYSTEM_SIM): $(SINGLE_CYCLE_FILE_SYSTEM_RTL) \
		$(SINGLE_CYCLE_FILE_SYSTEM_TESTBENCH) $(SINGLE_CYCLE_FILE_SYSTEM_IMAGES)
	mkdir -p $(SINGLE_CYCLE_FILE_SYSTEM_OBJ_DIR)
	$(VERILATOR) --cc --exe --build \
		--top-module single_cycle_file_system \
		--Mdir $(SINGLE_CYCLE_FILE_SYSTEM_OBJ_DIR) \
		$(SINGLE_CYCLE_FILE_SYSTEM_RTL) $(SINGLE_CYCLE_FILE_SYSTEM_TESTBENCH)

# ------------------------------
# 聚合入口只覆盖模块化单周期 CPU 及其文件内存系统测试。
lint:
	$(VERILATOR) --lint-only --Wall $(SINGLE_CYCLE_FILE_SYSTEM_RTL)

test: branch-unit-test pc-register-test next-pc-logic-test \
	single-cycle-core-test single-cycle-file-system-test

clean:
	rm -rf $(BUILD_DIR)
