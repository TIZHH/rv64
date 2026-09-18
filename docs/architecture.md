# Architecture

## Current design

The project contains two implementations: `single_cycle_cpu` is the reference
architecture, and `pipeline_cpu` is a five-stage IF/ID/EX/MEM/WB implementation.
Both use the shared decoder, ALU, and register file. Instruction and data memory
are simple testbench-facing interfaces; there is no bus protocol or cache.

On a rising clock edge:

- reset sets the PC to zero;
- otherwise the decoded instruction writes architectural state and the PC takes
  the sequential or control-flow target.

The Verilator C++ testbenches supply instruction words, model byte-addressed
memory, and check the resulting stores. This keeps architectural behavior
observable without adding a hardware bus.

The pipeline resolves branches and jumps in EX, forwards results from EX/MEM and
MEM/WB, and inserts a bubble for a load-use dependency.

## Planned structure

- `rtl/common/`: reusable datapath modules
- `rtl/single_cycle/`: single-cycle CPU integration
- `rtl/pipeline/`: five-stage implementation and hazard units
- `sim/verilator/`: Verilator testbench code
- `tests/asm/`: focused assembly tests added with instruction support

## Supported instructions

The implementation supports the RV64I base integer instruction groups:

- `ADD`, `SUB`, shifts, signed/unsigned compares, and bitwise register ALU
- immediate ALU operations and immediate shifts
- `LUI` and `AUIPC`
- `JAL`, `JALR`, and all six conditional branches
- `LB`, `LH`, `LW`, `LD`, `LBU`, `LHU`, and `LWU`
- `SB`, `SH`, `SW`, and `SD`
- `ADDIW`, immediate word shifts, and register word ALU operations

Alignment exceptions, privilege features, CSRs, interrupts, and excluded
extensions remain out of scope.
