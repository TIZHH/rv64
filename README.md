# RV64 CPU Lab

An educational RV64I single-cycle processor implemented in SystemVerilog and
verified with Verilator. This branch contains the modular single-cycle design
and its focused simulations.

## Current milestone

The modular single-cycle RV64I implementation is complete and split into
focused datapath, control-flow, memory, and writeback modules.

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
```

`make test` builds and runs all retained Verilator tests. Each test also has a
matching `*-model` target that generates its Verilator model without compiling
the C++ testbench. `make single-cycle-core-test` runs the architectural RV64I
regression through the modular single-cycle core.

The `single_cycle_core` splits PC state, next-PC selection, branch comparison,
memory formatting, and writeback into separate modules. The
`make single-cycle-file-system-test` target runs the file-backed system
wrapper, which loads instructions from `sim/images/instruction.hex` and data
bytes from `sim/images/data.hex`.

## Scope

The project targets the unprivileged RV64I base integer ISA only. Peripherals,
CSRs, interrupts, extensions, caches, privilege modes, virtual memory, and
operating-system support are intentionally out of scope.
