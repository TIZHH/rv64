VERILATOR ?= verilator
BUILD_DIR := build

.PHONY: help lint test clean \
	pipeline-cpu-model pipeline-cpu-test

help:
	@echo "可用目标:"
	@echo "  make lint                           检查五级流水线 RTL"
	@echo "  make test                           运行五级流水线 Verilator 回归测试"
	@echo "  make pipeline-cpu-model              生成五级流水线 CPU 模型"
	@echo "  make pipeline-cpu-test               运行五级流水线 RV64I 回归测试"
	@echo "  make clean                           删除生成的 Verilator 构建文件"

# ------------------------------
# pipeline_cpu：经典 IF/ID/EX/MEM/WB 五级 RV64I 流水线。
PIPELINE_CPU_RTL := rtl/common/alu.sv rtl/common/decoder.sv rtl/common/regfile.sv \
	rtl/pipeline/pipeline_execute.sv rtl/pipeline/pipeline_writeback.sv \
	rtl/pipeline/pipeline_memory_port.sv rtl/pipeline/pipeline_hazard.sv \
	rtl/pipeline/pipeline_cpu.sv
PIPELINE_CPU_TESTBENCH := sim/verilator/tb_pipeline.cpp sim/verilator/rv64i_tests.cpp
PIPELINE_CPU_OBJ_DIR := $(BUILD_DIR)/pipeline_cpu_obj_dir
PIPELINE_CPU_SIM := $(PIPELINE_CPU_OBJ_DIR)/Vpipeline_cpu

pipeline-cpu-model: $(PIPELINE_CPU_RTL)
	mkdir -p $(PIPELINE_CPU_OBJ_DIR)
	$(VERILATOR) --cc \
		--top-module pipeline_cpu \
		--Mdir $(PIPELINE_CPU_OBJ_DIR) \
		$^

pipeline-cpu-test: $(PIPELINE_CPU_SIM)
	$(PIPELINE_CPU_SIM)

$(PIPELINE_CPU_SIM): $(PIPELINE_CPU_RTL) $(PIPELINE_CPU_TESTBENCH)
	mkdir -p $(PIPELINE_CPU_OBJ_DIR)
	$(VERILATOR) --cc --exe --build \
		--top-module pipeline_cpu \
		--Mdir $(PIPELINE_CPU_OBJ_DIR) \
		$^

# ------------------------------
# 聚合入口只覆盖五级流水线测试。
lint:
	$(VERILATOR) --lint-only --Wall $(PIPELINE_CPU_RTL)

test: pipeline-cpu-test

clean:
	rm -rf $(BUILD_DIR)
