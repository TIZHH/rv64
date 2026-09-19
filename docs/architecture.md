# Architecture

## Current design

The project contains three CPU-facing entry points: `single_cycle_cpu` is the
original reference architecture, `single_cycle_core` is an equivalent modular
single-cycle implementation, and `pipeline_cpu` is a five-stage
IF/ID/EX/MEM/WB implementation. All use the shared decoder, ALU, and register
file. The original single-cycle top is preserved as a learning/reference
version.

The modular single-cycle path separates the following responsibilities:

- `pc_register.sv`: reset and sequential PC state;
- `next_pc_logic.sv`: sequential, branch, JAL, and JALR target selection;
- `branch_unit.sv`: signed and unsigned branch comparisons;
- `memory_access.sv`: load extension and store byte-mask generation;
- `writeback_mux.sv`: ALU, load, link, LUI, and AUIPC writeback selection;
- `single_cycle_core.sv`: datapath wiring and instruction-level control.

`single_cycle_file_system.sv` connects that core to separate file-backed
instruction and data memories. The default instruction memory contains 256
32-bit words, and the default data memory contains 4096 bytes. Both are
initialized with `$readmemh`; the data image is byte-oriented and supports
`@address` markers.

On a rising clock edge:

- reset sets the PC to zero;
- otherwise the decoded instruction writes architectural state and the PC takes
  the sequential or control-flow target.

The Verilator C++ testbenches supply instruction words to both single-cycle
cores, model byte-addressed memory, and check the resulting stores. The
file-backed smoke test exercises the system wrapper without a C++ instruction
loader. This keeps architectural behavior observable without adding a bus
protocol or cache.

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
