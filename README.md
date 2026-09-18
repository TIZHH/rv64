# RV64 CPU Lab

An educational RV64I processor implemented in SystemVerilog and verified with
Verilator. Development proceeds from a single-cycle CPU to a classic five-stage
pipeline.

## Current milestone

The complete SC-08 single-cycle RV64I implementation is implemented. It
supports integer ALU operations, immediate and upper-immediate operations,
branches, jumps, loads, stores, and RV64 word operations. Illegal instructions
are exposed through the `illegal_instruction` simulation output.

## Requirements

- Verilator
- GNU Make
- A C++ compiler supported by Verilator

## Commands

```sh
make help
make lint
make test
```

`make test` builds the Verilator model and runs the single-cycle RV64I
regression, including focused arithmetic, control-flow, memory, word-operation,
and illegal-instruction checks.

## Scope

The project targets the unprivileged RV64I base integer ISA only. Peripherals,
CSRs, interrupts, extensions, caches, privilege modes, virtual memory, and
operating-system support are intentionally out of scope.
