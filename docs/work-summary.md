# 五级流水线 RV64I CPU 工作总结

## 已完成工作

流水线实现包含显式的：

- IF/ID 流水线寄存器
- ID/EX 流水线寄存器
- EX/MEM 流水线寄存器
- MEM/WB 流水线寄存器

已实现：

- EX/MEM 到 EX 的数据前递
- MEM/WB 到 EX 的数据前递
- ID 阶段写回旁路
- load-use 冒险检测
- load-use 停顿和气泡插入
- 分支和跳转目标计算
- 控制流改变后的流水线冲刷
- 流水线加载和存储

主要文件：

```text
rtl/common/alu.sv
rtl/common/decoder.sv
rtl/common/regfile.sv
rtl/pipeline/pipeline_cpu.sv
rtl/pipeline/pipeline_execute.sv
rtl/pipeline/pipeline_hazard.sv
rtl/pipeline/pipeline_memory_port.sv
rtl/pipeline/pipeline_writeback.sv
```

## 验证方式

Verilator C++ 测试台提供指令、数据和简单的字节寻址内存模型，通过最终
存储结果检查流水线行为。

```sh
make lint
make test
```

测试覆盖算术运算、立即数运算、上位立即数、分支、跳转、加载、存储、
RV64 `W` 类指令、非法指令行为以及流水线数据依赖场景。

## 当前限制

以下功能不在当前分支范围内：

- Cache 和分支预测
- CSR 和特权模式
- 中断和异常处理
- `M`、`A`、`F`、`D` 扩展
- MMU、虚拟内存和操作系统支持
- UART、定时器和其他外设
- AXI、AHB、APB 等复杂总线协议
