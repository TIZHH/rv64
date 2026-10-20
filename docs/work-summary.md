# 模块化单周期 RV64I CPU 工作总结

## 项目目标

本分支专注于使用 SystemVerilog 实现模块化的 RV64I 单周期 CPU，并使用
Verilator 进行构建和功能验证。

## 已完成工作

模块化单周期实现已经完成，包含：

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

主要实现文件：

```text
rtl/common/alu.sv
rtl/common/decoder.sv
rtl/common/regfile.sv
rtl/single_cycle_modular/*.sv
rtl/memory/*.sv
```

## 验证方式

Verilator 测试台提供指令、数据和简单的字节寻址内存模型，通过最终存储
结果检查 CPU 行为。文件内存测试使用 `sim/images/` 中的指令和数据镜像。

```sh
make lint
make test
```

测试覆盖算术运算、立即数运算、上位立即数、分支、跳转、加载、存储、
RV64 `W` 类指令和非法指令行为。

## 当前限制

以下功能不在当前分支范围内：

- CSR 和特权模式
- 中断和异常处理
- `M`、`A`、`F`、`D` 扩展
- MMU、虚拟内存和操作系统支持
- Cache 和分支预测
- UART、定时器和其他外设
- AXI、AHB、APB 等复杂总线协议
