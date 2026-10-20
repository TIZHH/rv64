# RV64 Pipeline CPU Lab

An educational five-stage RV64I pipeline implemented in SystemVerilog and
verified with Verilator.

## Current design

This branch contains the `pipeline_cpu` IF/ID/EX/MEM/WB implementation. It
includes EX/MEM and MEM/WB forwarding, load-use stalls, and control-flow
flushing. Instruction and data memories are supplied by the C++ testbench; no
cache or peripheral is included.

## Requirements

- Verilator
- GNU Make
- A C++ compiler supported by Verilator

## Commands

```sh
make help
make lint
make test
make pipeline-cpu-model
make pipeline-cpu-test
make clean
```

`make test` builds and runs the complete five-stage pipeline RV64I regression.
`make pipeline-cpu-model` generates the Verilator model without compiling the
C++ testbench. `make pipeline-cpu-test` builds and runs the testbench.

## Scope

The project targets the unprivileged RV64I base integer ISA only. Caches,
CSRs, interrupts, privilege modes, virtual memory, operating systems,
peripherals, and complex bus protocols are out of scope.
