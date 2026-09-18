# 当前代码介绍

本项目目前已经完成一个可运行的单周期 RV64I CPU，并使用 Verilator
进行构建和功能验证。

## 代码结构

### `rtl/common/alu.sv`

实现整数算术、逻辑、比较和移位运算，同时支持 RV64I 的 32 位 `W`
类运算。`W` 类指令只处理低 32 位，并将结果符号扩展到 64 位。

### `rtl/common/decoder.sv`

解析 32 位 RISC-V 指令，生成寄存器写回、访存、分支、跳转、ALU
操作和立即数等控制信号。非法或未实现的编码不会产生有效写回。

### `rtl/common/regfile.sv`

实现 32 个 64 位整数寄存器。寄存器 `x0` 始终读取为零，对 `x0`
的写操作会被忽略。

### `rtl/single_cycle/single_cycle_cpu.sv`

连接解码器、寄存器文件和 ALU，完成单周期取指、执行、访存、写回和
下一条 PC 计算。该模块提供简单的指令和数据存储器接口，并输出非法
指令状态和部分调试寄存器。

### `sim/verilator/tb_single_cycle.cpp`

Verilator 仿真入口。它负责复位 CPU、驱动时钟、提供指令和数据、处理
存储写掩码，并检查测试程序的最终结果。

### `sim/verilator/rv64i_tests.cpp`

包含 RV64I 测试程序及机器码编码辅助函数，覆盖：

- 寄存器和立即数 ALU 指令
- `LUI` 与 `AUIPC`
- 分支、`JAL` 和 `JALR`
- 字节、半字、字和双字加载/存储
- RV64I `W` 类指令
- 非法指令可见性

## 构建与测试

```sh
make lint
make test
```

`make lint` 使用 Verilator 检查 RTL；`make test` 会构建仿真程序并运行
完整的单周期 RV64I 回归测试。

## 当前范围

目前只实现 RV64I 基础整数指令集和单周期架构。CSR、中断、特权模式、
缓存、虚拟内存、乘除法扩展和外设均不在当前范围内。五级流水线将在
后续阶段单独实现。
