# Modular Single-Cycle CPU

The repository preserves the original single-cycle implementation in
`rtl/single_cycle/single_cycle_cpu.sv`. The refactored implementation is in
`rtl/single_cycle_modular/` and is intended to be easier to study one concern
at a time.

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
