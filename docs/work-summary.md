# RV64 CPU 项目工作总结

## 项目目标

本项目使用 SystemVerilog 实现 RV64I 基础整数处理器，并使用 Verilator
进行构建和验证。项目包含两个架构阶段：

1. 单周期 RV64I CPU
2. 五级流水线 RV64I CPU

## 已完成工作

### 单周期 CPU

单周期实现已经完成，包含：

- 64 位 PC 和 32 个 64 位整数寄存器
- `x0` 恒为零，写入 `x0` 会被忽略
- RV64I 指令解码和立即数生成
- 整数 ALU 运算：加法、减法、移位、比较和逻辑运算
- 立即数运算和立即数移位
- `LUI`、`AUIPC`
- `JAL`、`JALR`
- `BEQ`、`BNE`、`BLT`、`BGE`、`BLTU`、`BGEU`
- `LB`、`LH`、`LW`、`LD`、`LBU`、`LHU`、`LWU`
- `SB`、`SH`、`SW`、`SD`
- `ADDIW`、字移位和寄存器字运算
- 非法指令状态输出

主要文件：

```text
rtl/common/alu.sv
rtl/common/decoder.sv
rtl/common/regfile.sv
rtl/single_cycle/single_cycle_cpu.sv
```

### 五级流水线 CPU

流水线实现已经完成 IF、ID、EX、MEM、WB 五个阶段，并使用显式流水线
寄存器保存阶段状态：

- IF/ID
- ID/EX
- EX/MEM
- MEM/WB

已实现：

- EX/MEM 到 EX 的前递
- MEM/WB 到 EX 的前递
- ID 阶段写回旁路
- load-use 冒险检测
- load-use 停顿和气泡插入
- 分支和跳转目标计算
- 控制流改变后的流水线冲刷
- 流水线加载和存储

主要文件：

```text
rtl/pipeline/pipeline_cpu.sv
rtl/pipeline/pipeline_execute.sv
rtl/pipeline/pipeline_hazard.sv
rtl/pipeline/pipeline_memory_port.sv
rtl/pipeline/pipeline_writeback.sv
```

## 验证方式

Verilator 测试台提供指令、数据和简单的字节寻址内存模型，通过最终存储
结果检查 CPU 行为。

单周期测试：

```sh
make lint
make test
```

流水线测试：

```sh
make pipeline-lint
make pipeline-test
```

当前两套回归均通过：

```text
PASS: all single-cycle RV64I tests
PASS: pipeline RV64I regression
```

测试覆盖算术运算、立即数运算、上位立即数、分支、跳转、加载、存储、
RV64 `W` 类指令和非法指令行为，并包含流水线相关的数据依赖场景。

## Git 里程碑

项目使用 Git 保存工作里程碑，主要提交包括：

```text
bf3e608  feat: complete single-cycle rv64i execution
9ab6a45  fix: use current pc for auipc
b221fc2  feat: add five-stage rv64i pipeline
```

后续可以为稳定版本创建标签：

```sh
git tag single-cycle-rv64i
git tag five-stage-rv64i
```

## 当前限制

以下功能不在当前项目范围内：

- CSR 和特权模式
- 中断和异常处理
- `M`、`A`、`F`、`D` 扩展
- MMU、虚拟内存和操作系统支持
- Cache 和分支预测
- UART、定时器和其他外设
- AXI、AHB、APB 等复杂总线协议

当前测试主要通过 C++ 机器码编码器生成指令。独立的汇编测试目录和与
参考模拟器的自动差分测试可以作为后续验证增强工作。

## 下一步建议

1. 增加 `tests/asm/` 汇编测试和编译流程。
2. 添加单周期与流水线的自动差分测试。
3. 增加非零地址偏移、边界移位量和分支不成立场景。
4. 创建单周期和流水线正式 Git 标签。
