# RV64I 指令速查表

> 用途：看到一条 32-bit RISC-V 指令时，能根据 bit 字段识别它，并知道它会做什么。
>
> 本表覆盖当前 CPU decoder 中实现的 RV64I 指令。

---

## 1. 先记住：RV64 的指令仍然通常是 32 bit

`RV64` 的 `64` 主要表示：

- 通用寄存器 `x0 ~ x31` 是 64 bit
- ALU 主要处理 64-bit 整数
- PC / 地址按 64 bit 处理
- 支持 `LD / SD`
- 支持 `ADDW / SUBW / ADDIW` 这类 32-bit word 运算

普通 RV64I 指令本身仍然通常是：

```text
31                              0
+--------------------------------+
|          32-bit instruction    |
+--------------------------------+
```

---

# 2. 最重要的字段

```text
[ 6: 0] opcode
[11: 7] rd
[14:12] funct3
[19:15] rs1
[24:20] rs2
[31:25] funct7
```

识别一条指令时，基本按照：

```text
opcode
  ↓
funct3
  ↓
funct7 / 其他高位字段
```

来判断。

---

# 3. 六种基本格式

## R-Type

用于寄存器和寄存器运算：

```text
31       25 24    20 19    15 14    12 11     7 6       0
+-----------+--------+--------+---------+---------+---------+
|  funct7   |  rs2   |  rs1   | funct3 |   rd    | opcode |
+-----------+--------+--------+---------+---------+---------+
```

---

## I-Type

用于立即数、Load、JALR：

```text
31                  20 19    15 14    12 11     7 6       0
+----------------------+--------+---------+---------+---------+
|      imm[11:0]       |  rs1   | funct3 |   rd    | opcode |
+----------------------+--------+---------+---------+---------+
```

---

## S-Type

用于 Store：

```text
31       25 24    20 19    15 14    12 11      7 6       0
+-----------+--------+--------+---------+----------+---------+
| imm[11:5] |  rs2   |  rs1   | funct3 | imm[4:0] | opcode |
+-----------+--------+--------+---------+----------+---------+
```

---

## B-Type

用于 Branch：

```text
31      30:25     24:20 19:15 14:12 11:8      7       6:0
imm[12] imm[10:5]  rs2   rs1   funct3 imm[4:1] imm[11] opcode
```

---

## U-Type

用于 LUI / AUIPC：

```text
31                                  12 11     7 6       0
+--------------------------------------+---------+---------+
|             imm[31:12]               |   rd    | opcode |
+--------------------------------------+---------+---------+
```

---

## J-Type

用于 JAL：

```text
31      30:21      20      19:12      11:7 6:0
imm[20] imm[10:1] imm[11] imm[19:12]   rd  opcode
```

---

# 4. 寄存器运算：OP

统一 opcode：

```text
0110011
```

格式：

```text
funct7  rs2  rs1  funct3  rd  0110011
```

| 指令 | funct7 | funct3 | 操作 |
|---|---|---|---|
| ADD | `0000000` | `000` | `rd = rs1 + rs2` |
| SUB | `0100000` | `000` | `rd = rs1 - rs2` |
| SLL | `0000000` | `001` | `rd = rs1 << rs2[5:0]` |
| SLT | `0000000` | `010` | 有符号比较，`rs1 < rs2` 时 rd=1 |
| SLTU | `0000000` | `011` | 无符号比较，`rs1 < rs2` 时 rd=1 |
| XOR | `0000000` | `100` | `rd = rs1 ^ rs2` |
| SRL | `0000000` | `101` | 逻辑右移，高位补 0 |
| SRA | `0100000` | `101` | 算术右移，高位补符号位 |
| OR | `0000000` | `110` | `rd = rs1 \| rs2` |
| AND | `0000000` | `111` | `rd = rs1 & rs2` |

例：

```text
0000000 00010 00001 000 00101 0110011
```

可以读成：

```text
funct7 = 0000000
rs2    = x2
rs1    = x1
funct3 = 000
rd     = x5
opcode = 0110011
```

所以是：

```asm
add x5, x1, x2
```

---

# 5. 立即数运算：OP-IMM

统一 opcode：

```text
0010011
```

基本格式：

```text
imm[11:0]  rs1  funct3  rd  0010011
```

| 指令 | funct3 | 操作 |
|---|---|---|
| ADDI | `000` | `rd = rs1 + imm` |
| SLTI | `010` | 有符号比较 `rs1 < imm` |
| SLTIU | `011` | 无符号比较 `rs1 < imm` |
| XORI | `100` | `rd = rs1 ^ imm` |
| ORI | `110` | `rd = rs1 \| imm` |
| ANDI | `111` | `rd = rs1 & imm` |

这里的 `imm[11:0]` 会符号扩展到 64 bit。

---

# 6. 立即数移位

仍然使用：

```text
opcode = 0010011
```

## SLLI

```text
31:26   25:20      19:15 14:12 11:7 6:0
000000  shamt[5:0]  rs1   001    rd  0010011
```

```text
rd = rs1 << shamt
```

## SRLI

```text
000000  shamt[5:0]  rs1  101  rd  0010011
```

```text
逻辑右移
```

## SRAI

```text
010000  shamt[5:0]  rs1  101  rd  0010011
```

```text
算术右移
```

RV64 中 shift amount 是 6 bit：

```text
0 ~ 63
```

---

# 7. Load

统一 opcode：

```text
0000011
```

格式：

```text
imm[11:0]  rs1  funct3  rd  0000011
```

地址统一为：

```text
address = rs1 + imm
```

| 指令 | funct3 | 操作 |
|---|---|---|
| LB | `000` | 读 8 bit，符号扩展到 64 bit |
| LH | `001` | 读 16 bit，符号扩展到 64 bit |
| LW | `010` | 读 32 bit，符号扩展到 64 bit |
| LD | `011` | 读 64 bit |
| LBU | `100` | 读 8 bit，零扩展到 64 bit |
| LHU | `101` | 读 16 bit，零扩展到 64 bit |
| LWU | `110` | 读 32 bit，零扩展到 64 bit |

例如：

```asm
ld x5, 8(x1)
```

表示：

```text
address = x1 + 8
x5 = memory[address] 的 64-bit 数据
```

---

# 8. Store

统一 opcode：

```text
0100011
```

格式：

```text
imm[11:5]  rs2  rs1  funct3  imm[4:0]  0100011
```

地址：

```text
address = rs1 + imm
```

| 指令 | funct3 | 操作 |
|---|---|---|
| SB | `000` | 写 rs2 的低 8 bit |
| SH | `001` | 写 rs2 的低 16 bit |
| SW | `010` | 写 rs2 的低 32 bit |
| SD | `011` | 写 rs2 的 64 bit |

例如：

```asm
sd x2, 16(x1)
```

表示：

```text
memory[x1 + 16] = x2
```

---

# 9. Branch

统一 opcode：

```text
1100011
```

格式：

```text
imm[12] imm[10:5] rs2 rs1 funct3 imm[4:1] imm[11] 1100011
```

如果条件成立：

```text
pc = pc + imm
```

否则：

```text
pc = pc + 4
```

| 指令 | funct3 | 条件 |
|---|---|---|
| BEQ | `000` | `rs1 == rs2` |
| BNE | `001` | `rs1 != rs2` |
| BLT | `100` | signed `rs1 < rs2` |
| BGE | `101` | signed `rs1 >= rs2` |
| BLTU | `110` | unsigned `rs1 < rs2` |
| BGEU | `111` | unsigned `rs1 >= rs2` |

---

# 10. JAL

opcode：

```text
1101111
```

格式：

```text
imm[20] imm[10:1] imm[11] imm[19:12] rd 1101111
```

操作：

```text
rd = pc + 4
pc = pc + imm
```

也就是说：

```text
先保存返回地址
再跳转
```

常见：

```asm
jal x1, function
```

因为：

```text
x1 = ra
```

所以经常用于函数调用。

---

# 11. JALR

opcode：

```text
1100111
```

funct3：

```text
000
```

格式：

```text
imm[11:0]  rs1  000  rd  1100111
```

操作：

```text
rd = pc + 4
pc = (rs1 + imm) & ~1
```

与 JAL 区别：

```text
JAL：
目标 = pc + imm

JALR：
目标 = rs1 + imm
```

---

# 12. LUI

opcode：

```text
0110111
```

格式：

```text
imm[31:12]  rd  0110111
```

操作：

```text
rd = sign_extend({imm[31:12], 12'b0})
```

简单理解：

```text
把一个立即数放到高 20 bit，
低 12 bit 补 0。
```

---

# 13. AUIPC

opcode：

```text
0010111
```

格式：

```text
imm[31:12]  rd  0010111
```

操作：

```text
rd = pc + sign_extend({imm[31:12], 12'b0})
```

和 LUI 的区别：

```text
LUI:
rd = imm

AUIPC:
rd = pc + imm
```

---

# 14. RV64 Word 运算

名字结尾带 `W`：

```text
ADDW
SUBW
SLLW
SRLW
SRAW
ADDIW
SLLIW
SRLIW
SRAIW
```

共同特点：

```text
只计算低 32 bit
      ↓
得到 32-bit 结果
      ↓
符号扩展到 64 bit
      ↓
写入 rd
```

注意：

```text
W ≠ 无符号
W = Word = 32 bit
```

---

# 15. OP-32

opcode：

```text
0111011
```

格式：

```text
funct7 rs2 rs1 funct3 rd 0111011
```

| 指令 | funct7 | funct3 | 操作 |
|---|---|---|---|
| ADDW | `0000000` | `000` | 低 32-bit 加法 |
| SUBW | `0100000` | `000` | 低 32-bit 减法 |
| SLLW | `0000000` | `001` | 低 32-bit 左移 |
| SRLW | `0000000` | `101` | 低 32-bit 逻辑右移 |
| SRAW | `0100000` | `101` | 低 32-bit 算术右移 |

最终结果都：

```text
sign_extend(result[31:0])
```

---

# 16. OP-IMM-32

opcode：

```text
0011011
```

| 指令 | funct3 | 额外字段 | 操作 |
|---|---|---|---|
| ADDIW | `000` | - | 32-bit 加立即数 |
| SLLIW | `001` | `funct7=0000000` | 32-bit 左移 |
| SRLIW | `101` | `funct7=0000000` | 32-bit 逻辑右移 |
| SRAIW | `101` | `funct7=0100000` | 32-bit 算术右移 |

这里 shift amount 只有 5 bit：

```text
0 ~ 31
```

---

# 17. Opcode 速查

| 类型 | opcode |
|---|---|
| LOAD | `0000011` |
| OP-IMM | `0010011` |
| AUIPC | `0010111` |
| OP-IMM-32 | `0011011` |
| STORE | `0100011` |
| OP | `0110011` |
| LUI | `0110111` |
| OP-32 | `0111011` |
| BRANCH | `1100011` |
| JALR | `1100111` |
| JAL | `1101111` |

---

# 18. 最实用的识别流程

拿到一个 32-bit instruction：

```text
STEP 1
看 [6:0]
↓
确定 opcode 大类

STEP 2
看 [14:12]
↓
确定 funct3

STEP 3
如果还不能确定
看 [31:25] 或 [31:26]
↓
确定 funct7 / shift 类型

STEP 4
根据指令格式读出
rd / rs1 / rs2 / imm

STEP 5
写出这条指令真正做的操作
```

例如：

```text
0100000 00010 00001 000 00101 0110011
```

先看：

```text
opcode = 0110011
```

所以是：

```text
OP / R-Type
```

再看：

```text
funct3 = 000
funct7 = 0100000
```

因此：

```text
SUB
```

寄存器：

```text
rs1 = 00001 = x1
rs2 = 00010 = x2
rd  = 00101 = x5
```

最终：

```asm
sub x5, x1, x2
```

操作：

```text
x5 = x1 - x2
```

---

# 19. 最值得记住的一张图

```text
R-Type
funct7 | rs2 | rs1 | funct3 | rd | opcode

I-Type
imm[11:0] | rs1 | funct3 | rd | opcode

S-Type
imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode

B-Type
imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode

U-Type
imm[31:12] | rd | opcode

J-Type
imm[20] | imm[10:1] | imm[11] | imm[19:12] | rd | opcode
```

---

# 20. 一句话总结

识别 RISC-V 指令：

```text
先看 opcode
再看 funct3
需要时再看 funct7
最后根据 R/I/S/B/U/J 格式拆 rd、rs1、rs2、imm
```

知道指令以后，再把它翻译成：

```text
谁作为输入？
做什么运算？
结果写到哪里？
PC 是否变化？
是否访问内存？
```

这样就能从机器码直接理解 CPU 要做什么。
