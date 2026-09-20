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
	@echo "可用目标:"
	@echo "  make build             构建旧版单周期 Verilator 模型"
	@echo "  make lint              检查旧版单周期 RTL"
	@echo "  make test              运行旧版完整 RV64I 回归测试"
	@echo "  make branch-unit-test  单独测试 branch_unit 模块"
	@echo "  make modular-lint      检查模块化核心和文件内存"
	@echo "  make modular-test      在模块化核心上运行完整 RV64I 回归测试"
	@echo "  make file-memory-test  从 instruction.hex/data.hex 启动测试"
	@echo "  make pipeline-lint     检查五级流水线 RTL"
	@echo "  make pipeline-test     在五级流水线上运行完整 RV64I 回归测试"
	@echo "  make clean             删除生成的 Verilator 构建文件"

# 旧版单周期 CPU：由外部 C++ 测试台提供指令并模拟按字节寻址的数据内存。
# 这是项目保留的原始参考顶层。
build: $(SIM)

$(SIM): $(RTL) $(TESTBENCH)
	mkdir -p $(OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module $(TOP) \
		--Mdir $(OBJ_DIR) $(RTL) $(TESTBENCH)

# 只检查旧版单周期 RTL；不会在这里编译 C++ 测试台。
lint:
	$(VERILATOR) --lint-only --Wall $(RTL)

# 旧版单周期 CPU 的完整架构回归测试。测试用例定义在
# sim/verilator/rv64i_tests.cpp，覆盖 ALU、控制流、访存、W 指令和非法指令可见性。
test: build
	$(SIM)

BRANCH_UNIT_OBJ_DIR := $(BUILD_DIR)/branch_unit_obj_dir
BRANCH_UNIT_SIM := $(BRANCH_UNIT_OBJ_DIR)/Vbranch_unit

# 独立组合逻辑单元测试：包含 BEQ/BNE/BLT/BGE/BLTU/BGEU 的 13 个真值表用例，
# 同时检查有符号/无符号比较以及不支持的分支类型。
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

# 构建模块化单周期核心。这里不包含文件内存封装，方便使用同一套外部内存回归测试。
modular-build: $(MODULAR_CORE_SIM)

$(MODULAR_CORE_SIM): $(MODULAR_CORE_RTL) $(MODULAR_CORE_TESTBENCH)
	mkdir -p $(MODULAR_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module single_cycle_core \
		--Mdir $(MODULAR_OBJ_DIR) $(MODULAR_CORE_RTL) $(MODULAR_CORE_TESTBENCH)

# 检查模块化核心、拆分后的数据通路/控制模块以及两个内存模块。
modular-lint:
	$(VERILATOR) --lint-only --Wall $(MODULAR_SYSTEM_RTL)

# 在 single_cycle_core 上运行完整 RV64I 测试表，验证端口和数据通路模块化之后的
# 架构行为，而不只是检查模块是否能够连接。
modular-test: modular-build
	$(MODULAR_CORE_SIM)

# 文件内存集成 smoke test。CPU 从 instruction.hex 取指，从 data.hex 加载数据，
# 执行 ADDI，并把结果写回地址 0x100。
file-memory-test: $(MODULAR_SYSTEM_SIM)
	$(MODULAR_SYSTEM_SIM)

$(MODULAR_SYSTEM_SIM): $(MODULAR_SYSTEM_RTL) $(MODULAR_SYSTEM_TESTBENCH) \
	sim/images/instruction.hex sim/images/data.hex
	mkdir -p $(MODULAR_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module single_cycle_file_system \
		--Mdir $(MODULAR_OBJ_DIR) $(MODULAR_SYSTEM_RTL) $(MODULAR_SYSTEM_TESTBENCH)

# 五级流水线构建和回归测试使用与两个单周期实现相同的架构测试表，
# 方便直接比较三种实现的行为。
pipeline-build: $(PIPELINE_SIM)

$(PIPELINE_SIM): $(PIPELINE_RTL) $(PIPELINE_TESTBENCH)
	mkdir -p $(PIPELINE_OBJ_DIR)
	$(VERILATOR) --cc --exe --build --top-module pipeline_cpu \
		--Mdir $(PIPELINE_OBJ_DIR) $(PIPELINE_RTL) $(PIPELINE_TESTBENCH)

# 检查 IF/ID/EX/MEM/WB 流水线以及冒险处理和前递模块。
pipeline-lint:
	$(VERILATOR) --lint-only --Wall $(PIPELINE_RTL)

# 在五级流水线实现上运行完整 RV64I 架构回归测试。
pipeline-test: pipeline-build
	$(PIPELINE_SIM)

# 删除所有生成的 Verilator 模型和目标文件。
clean:
	rm -rf $(BUILD_DIR)
