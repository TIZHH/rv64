# Modular Single-Cycle CPU

The modular single-cycle implementation is in `rtl/single_cycle_modular/` and
is intended to be easier to study one concern at a time.

## Port naming convention

Every port in the modular single-cycle path and in `rtl/memory/` carries a
directional suffix, so an instantiation shows the direction without opening the
module:

```text
*_i    input to the module
*_o    output from the module
```

Example:

```systemverilog
branch_unit branch_comparator (
    .branch_type_i(branch_type),
    .left_i(register_a),
    .right_i(register_b),
    .taken_o(branch_taken)
);
```

The connected net keeps a plain value name (`branch_type`, `register_a`), which
reads as "the value being carried", while the port name states the direction.

The convention is applied to:

- `rtl/single_cycle_modular/*.sv`
- `rtl/memory/*.sv`

The shared modules `rtl/common/decoder.sv`, `rtl/common/alu.sv`, and
`rtl/common/regfile.sv` are intentionally left unchanged because the modular
single-cycle core and the pipeline instantiate them. At the core, their
connections still reveal direction through the net name, for example
`.instruction(instruction_i)`.

## Full signal diagram

- [SVG signal diagram](single-cycle-modular.svg)
- [Mermaid source](single-cycle-modular.mmd)

The SVG is the primary reading diagram. Blue wires are data/address buses,
orange wires are control signals, green wires are PC/state paths, purple wires
are immediates, and dashed gray wires are clock/reset or debug paths.

## Datapath modules

```text
single_cycle_core.sv
├── decoder
├── regfile
├── alu
├── branch_unit
├── memory_access
├── writeback_mux
├── next_pc_logic
└── pc_register
```

The core still completes one instruction between clock edges. Only the PC and
register file are architectural sequential state in the core. The data memory
is sequential state in the file-backed system wrapper.

## File-backed system

`single_cycle_file_system.sv` connects:

```text
PC → instruction_memory → instruction
                         ↓
                    single_cycle_core
                         ↓
data_memory ← address/read/write signals
```

Default images:

- `sim/images/instruction.hex`: one 32-bit instruction per line;
- `sim/images/data.hex`: one byte per line, with optional `@hex_address` markers.

The default memory sizes are 256 instruction words and 4096 data bytes.

## Verification commands

```sh
make modular-lint
make modular-test
make file-memory-test
```

`modular-test` runs the complete existing RV64I regression against the new
modular core. `file-memory-test` boots the core from the two image files, loads
a value from the data image, adds to it, and stores the result at `0x100`.
