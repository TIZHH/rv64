# Architecture

## Current design

The project contains two CPU-facing entry points: `single_cycle_core` is the
modular single-cycle implementation, and `pipeline_cpu` is a five-stage
IF/ID/EX/MEM/WB implementation. Both use the shared decoder, ALU, and register
file.

The modular single-cycle path separates the following responsibilities:

- `pc_register.sv`: reset and sequential PC state;
- `next_pc_logic.sv`: sequential, branch, JAL, and JALR target selection;
- `branch_unit.sv`: signed and unsigned branch comparisons;
- `memory_access.sv`: load extension and store byte-mask generation;
- `writeback_mux.sv`: ALU, load, link, LUI, and AUIPC writeback selection;
- `single_cycle_core.sv`: datapath wiring and instruction-level control.

Every port in `rtl/single_cycle_modular/`, `rtl/memory/`, and `rtl/pipeline/`
carries a directional suffix (`*_i` for input, `*_o` for output) so an
instantiation is readable without opening the module. The shared
`rtl/common/` modules keep their original port names because the modular
single-cycle core and the pipeline both instantiate them.

`single_cycle_file_system.sv` connects that core to separate file-backed
instruction and data memories. The default instruction memory contains 256
32-bit words, and the default data memory contains 4096 bytes. Both are
initialized with `$readmemh`; the data image is byte-oriented and supports
`@address` markers.

The file-backed system uses separate instruction and data address spaces rather
than one unified physical map:

| Space | Default range | Addressing | Source |
| --- | --- | --- | --- |
| Instruction | `0x0000` - `0x03fc` | 32-bit words at 4-byte PC increments | `sim/images/instruction.hex` |
| Data | `0x0000` - `0x0fff` | Bytes, with load/store masks | `sim/images/data.hex` |

Reset sets the PC to `0x0000`. Instruction address `PC` selects word
`PC >> 2`, so the first three image entries execute at `0x0000`, `0x0004`, and
`0x0008`. The default data image places byte `0x05` at address `0x0080`; the
file-backed smoke program writes its result at `0x0100`, which is also the
default debug observation address. Identical numeric addresses in the two
spaces do not conflict because instruction and data storage are separate.

On a rising clock edge:

- reset sets the PC to zero;
- otherwise the decoded instruction writes architectural state and the PC takes
  the sequential or control-flow target.

The Verilator C++ testbench supplies instruction words to the modular
single-cycle core and the pipeline, models byte-addressed memory, and checks
the resulting stores. The file-backed smoke test exercises the system wrapper
without a C++ instruction loader. This keeps architectural behavior observable
without adding a bus protocol or cache.

The pipeline resolves branches and jumps in EX, forwards results from EX/MEM and
MEM/WB, and inserts a bubble for a load-use dependency.

## Planned structure

- `rtl/common/`: reusable datapath modules
- `rtl/single_cycle_modular/`: modular single-cycle CPU integration
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
