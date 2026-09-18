# Architecture

## Current design

The current SC-08 design is a single-cycle SystemVerilog CPU named
`single_cycle_cpu`. The datapath is split into a decoder, ALU, and register file.
Instruction and data memory are simple synchronous-testbench-facing interfaces;
there is no bus protocol or cache.

On a rising clock edge:

- reset sets the PC to zero;
- otherwise the decoded instruction writes architectural state and the PC takes
  the sequential or control-flow target.

The Verilator C++ testbench supplies instruction words, models byte-addressed
memory, and checks the resulting stores. This keeps architectural behavior
observable without adding a hardware bus.

## Planned structure

- `rtl/common/`: reusable datapath modules
- `rtl/single_cycle/`: single-cycle CPU integration
- `rtl/pipeline/`: future five-stage implementation
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

The CPU does not yet implement the five-stage pipeline. Alignment exceptions,
privilege features, CSRs, interrupts, and excluded extensions remain out of
scope.
