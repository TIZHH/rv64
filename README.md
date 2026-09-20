# RV64 CPU Lab

An educational RV64I processor implemented in SystemVerilog and verified with
Verilator. Development proceeds from a single-cycle CPU to a classic five-stage
pipeline.

## Current milestone

The complete SC-08 single-cycle RV64I implementation and PL-06 five-stage
pipeline are implemented. The pipeline includes EX/MEM and MEM/WB forwarding,
load-use stalls, and control-flow flushing.

## Requirements

- Verilator
- GNU Make
- A C++ compiler supported by Verilator

## Commands

```sh
make help
make lint
make test
make branch-unit-test
make pc-register-test
make next-pc-logic-test
make single-cycle-core-test
make single-cycle-file-system-test
make pipeline-cpu-test
```

`make test` builds and runs all retained Verilator tests. Each test also has a
matching `*-model` target that generates its Verilator model without compiling
the C++ testbench. `make single-cycle-core-test` and `make pipeline-cpu-test`
run the same architectural RV64I programs through the modular single-cycle and
five-stage implementations.

The original `single_cycle_cpu` remains the reference implementation. The
new `single_cycle_core` keeps the same behavior but splits PC state, next-PC
selection, branch comparison, memory formatting, and writeback into separate
modules. `make single-cycle-file-system-test` runs the file-backed system
wrapper, which loads instructions from `sim/images/instruction.hex` and data
bytes from `sim/images/data.hex`.

## Scope

The project targets the unprivileged RV64I base integer ISA only. Peripherals,
CSRs, interrupts, extensions, caches, privilege modes, virtual memory, and
operating-system support are intentionally out of scope.
