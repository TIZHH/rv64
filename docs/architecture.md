# Pipeline Architecture

## Current design

This branch contains one CPU-facing entry point:

```text
pipeline_cpu
```

The CPU uses the classic five stages:

```text
IF → ID → EX → MEM → WB
```

Explicit pipeline registers are maintained between stages:

```text
IF/ID → ID/EX → EX/MEM → MEM/WB
```

The shared `rtl/common/` modules provide the decoder, ALU, and register file.
The `rtl/pipeline/` modules implement the pipeline datapath, forwarding,
hazard detection, memory-port formatting, and writeback.

## Hazards and control flow

The EX stage accepts forwarded values from EX/MEM and MEM/WB. The ID stage also
has a writeback bypass for register reads occurring in the same cycle as a
writeback.

Load-use dependencies are detected in ID. The hazard unit holds the PC and
IF/ID register and inserts a bubble into ID/EX for one cycle.

Branches and jumps are resolved in EX. A taken control-flow instruction updates
the PC and flushes younger instructions in IF/ID and ID/EX.

## Memory interface

`pipeline_cpu` does not contain a cache or a memory array. It exposes separate
instruction and data interfaces:

- `instruction_i`: instruction supplied for the current PC;
- `data_*`: byte-addressed data read/write interface with an eight-bit write
  mask.

The Verilator C++ testbench supplies instructions from each test program and
models a 4096-byte data memory. This is a simulation model, not an integrated
instruction/data memory subsystem.

## Repository structure

```text
rtl/common/       shared ALU, decoder, and register file
rtl/pipeline/     five-stage pipeline RTL
sim/verilator/    pipeline testbench and RV64I test programs
docs/             pipeline documentation
```
