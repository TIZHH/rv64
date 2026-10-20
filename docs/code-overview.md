# Pipeline Code Overview

本分支只包含五级流水线 RV64I CPU 及其 Verilator 仿真代码。

## 共享模块

### `rtl/common/alu.sv`

实现整数算术、逻辑、比较和移位运算，同时支持 RV64I 的 32 位 `W`
类运算。

### `rtl/common/decoder.sv`

解析 32 位 RISC-V 指令并生成寄存器写回、访存、分支、跳转、ALU 操作和
立即数等控制信号。

### `rtl/common/regfile.sv`

实现 32 个 64 位整数寄存器。寄存器 `x0` 始终读取为零，对 `x0` 的写操作
会被忽略。

## 流水线模块

### `rtl/pipeline/pipeline_cpu.sv`

保存 IF/ID、ID/EX、EX/MEM、MEM/WB 状态，并连接五个流水线阶段。

### `rtl/pipeline/pipeline_execute.sv`

实现 EX 阶段 ALU、数据前递、分支判断和跳转目标计算。

### `rtl/pipeline/pipeline_hazard.sv`

检测 load-use 数据冒险并请求流水线停顿。

### `rtl/pipeline/pipeline_memory_port.sv`

根据访存大小和地址生成数据存储器读写信号及 byte mask。

### `rtl/pipeline/pipeline_writeback.sv`

处理 MEM/WB 阶段的加载扩展和写回数据选择。

## 仿真

### `sim/verilator/tb_pipeline.cpp`

Verilator 仿真入口，负责驱动时钟、提供指令、模拟数据内存并检查最终
存储结果。

### `sim/verilator/rv64i_tests.cpp`

包含 RV64I 测试程序和机器码编码辅助函数，覆盖算术、立即数、分支、跳转、
加载、存储、`W` 类指令、非法指令以及流水线数据依赖场景。

## 构建与测试

```sh
make lint
make test
```
