# RV64 CPU Lab

An educational RV64I processor implemented in SystemVerilog and verified with
Verilator. Development proceeds from a single-cycle CPU to a classic five-stage
pipeline.

## Current milestone

SC-00 project bootstrap is implemented. The single-cycle shell contains a
64-bit program counter that resets to zero and advances by four each cycle. No
instructions are decoded or executed yet.

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

`make test` builds the Verilator model and runs a bounded smoke test that checks
reset and sequential PC advancement.

## Scope

The project targets the unprivileged RV64I base integer ISA only. Peripherals,
CSRs, interrupts, extensions, caches, privilege modes, virtual memory, and
operating-system support are intentionally out of scope.
