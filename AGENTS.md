# AGENTS.md

## Project Overview

This project implements a RISC-V RV64I CPU from scratch in SystemVerilog.

The current short-term goal is to build a correct RV64I processor in two architectural stages:

1. A simple single-cycle RV64I CPU.
2. A classic five-stage pipelined RV64I CPU.

All CPU implementations must be verified using Verilator.

Development progress must be recorded using Git commits at meaningful, working milestones.

The project should remain small, understandable, and educational.

Do not prematurely add features that are outside the current milestone.

---

# Current Scope

The current project scope is strictly limited to:

* RV64I base integer ISA
* SystemVerilog RTL
* Single-cycle CPU
* Verilator simulation
* Assembly-level instruction tests
* Five-stage pipeline
* Pipeline hazards
* Forwarding
* Pipeline stalls
* Branch flushing
* Git-based milestone history

The current scope explicitly excludes:

* UART
* Timer
* GPIO
* AXI
* AHB
* APB
* external peripherals
* CSR
* interrupts
* exceptions beyond what is minimally necessary for detecting illegal simulation states
* M extension
* A extension
* F/D extensions
* privilege modes
* MMU
* virtual memory
* operating systems
* RTOS
* Linux
* xv6
* caches
* branch prediction
* superscalar execution
* out-of-order execution

Do not implement excluded features unless the project scope is explicitly updated.

---

# Primary Goal

The first major deliverable is:

> A complete, tested, understandable single-cycle RV64I CPU.

The second major deliverable is:

> A complete, tested, understandable five-stage pipelined RV64I CPU whose architectural behavior matches the single-cycle implementation.

Correctness is more important than performance.

Clarity is more important than cleverness.

---

# Development Philosophy

Work incrementally.

Never attempt to implement the entire RV64I CPU in one change.

Every development step should follow this loop:

1. Understand the required ISA behavior.
2. Make the smallest reasonable RTL change.
3. Add or update tests.
4. Build with Verilator.
5. Run regression tests.
6. Inspect failures.
7. Fix the implementation.
8. Confirm all previous tests still pass.
9. Commit the working milestone.
10. Continue to the next milestone.

Never intentionally leave the repository in a broken state before a milestone commit.

Do not create commits for code that does not build unless the commit is explicitly marked as an experimental checkpoint.

Prefer working milestone commits.

---

# Repository Structure

Prefer the following structure:

```text
rv64-lab/
├── AGENTS.md
├── README.md
├── Makefile
│
├── rtl/
│   ├── common/
│   ├── single_cycle/
│   └── pipeline/
│
├── sim/
│   ├── verilator/
│   └── common/
│
├── tests/
│   ├── asm/
│   └── expected/
│
├── scripts/
│
└── docs/
```

The structure may evolve when justified, but avoid unnecessary directory complexity.

---

# RTL Style

Use SystemVerilog.

Use `.sv` for RTL source files.

Prefer explicit modules with clear responsibilities.

Examples:

```text
decoder.sv
regfile.sv
alu.sv
imm_gen.sv
single_cycle_cpu.sv
pipeline_cpu.sv
```

Avoid putting the entire processor into one giant module.

However, do not over-engineer tiny pieces into dozens of unnecessary modules.

Use combinational logic for datapath selection and decode logic where appropriate.

Use sequential logic for architectural and pipeline state.

Prefer:

```systemverilog
always_comb
```

for combinational logic.

Prefer:

```systemverilog
always_ff @(posedge clk)
```

for sequential logic.

Avoid accidental latch inference.

Avoid multiple drivers.

Keep signal widths explicit.

Remember that RV64 has:

```text
XLEN = 64
```

while standard RV64I instructions are still:

```text
32 bits
```

unless compressed instructions are added in the future.

Compressed instructions are not currently in scope.

---

# Architectural State

For the current RV64I implementation, architectural state primarily consists of:

* PC
* integer registers x0-x31
* memory contents

Register x0 must always read as zero.

Writes to x0 must be ignored.

The initial implementation should make architectural state easy to observe from the Verilator testbench.

This is important for debugging and future differential testing.

---

# Instruction Implementation Strategy

Do not implement all RV64I instructions at once.

Implement instruction groups incrementally.

A recommended sequence is:

## Phase 1 — Minimal datapath

Start with:

```text
ADDI
```

The first useful test should verify something equivalent to:

```asm
addi x10, x0, 1
```

Expected final state:

```text
x10 = 1
```

---

## Phase 2 — Integer register-register operations

Implement:

```text
ADD
SUB
SLL
SLT
SLTU
XOR
SRL
SRA
OR
AND
```

---

## Phase 3 — Integer immediate operations

Implement:

```text
ADDI
SLTI
SLTIU
XORI
ORI
ANDI
SLLI
SRLI
SRAI
```

---

## Phase 4 — Upper immediates

Implement:

```text
LUI
AUIPC
```

---

## Phase 5 — Control flow

Implement:

```text
JAL
JALR

BEQ
BNE
BLT
BGE
BLTU
BGEU
```

---

## Phase 6 — Loads and stores

Implement:

```text
LB
LH
LW
LD
LBU
LHU
LWU

SB
SH
SW
SD
```

Pay careful attention to:

* byte addressing
* alignment assumptions
* sign extension
* zero extension
* write masks

---

## Phase 7 — RV64-specific word instructions

Implement:

```text
ADDIW

SLLIW
SRLIW
SRAIW

ADDW
SUBW
SLLW
SRLW
SRAW
```

Remember:

> W instructions operate on the low 32 bits and sign-extend the 32-bit result to 64 bits.

---

# Memory Model

For the first CPU implementation, use a simple simulation memory model.

Do not introduce a complex bus protocol.

The purpose of the initial memory interface is to support CPU verification.

Keep instruction and data memory behavior simple and deterministic.

A unified memory model is acceptable.

Separate instruction and data interfaces are also acceptable if they make the design clearer.

Do not add caches.

---

# Verilator

Verilator is the primary simulation backend.

The repository should support a simple command such as:

```bash
make test
```

or:

```bash
make sim
```

The exact interface may evolve, but building and running the simulator should remain simple.

The Verilator testbench should be able to:

* reset the CPU
* load machine code into simulated memory
* drive the clock
* execute for a bounded number of cycles
* inspect architectural state
* detect test completion
* detect timeout
* report failures clearly

A failed test must produce enough information to identify:

* PC
* instruction
* relevant registers
* expected result
* actual result

when reasonably possible.

---

# Tests

Every new instruction or instruction group must have tests.

Tests should be small.

Prefer tests that isolate one behavior.

Examples:

```text
addi_basic
addi_negative
add_basic
sub_basic
branch_taken
branch_not_taken
jal_link
jalr_basic
load_sign_extend
load_zero_extend
store_byte
store_doubleword
```

Do not rely only on one large program to verify the CPU.

Maintain regression tests so previously implemented instructions continue to work.

---

# Single-Cycle CPU Milestones

The recommended milestones are:

## SC-00 — Project bootstrap

Requirements:

* repository structure exists
* Verilator builds
* minimal clock/reset testbench works
* Makefile or equivalent build entry exists

Commit after completion.

Suggested commit:

```text
chore: bootstrap rv64 cpu project
```

---

## SC-01 — Minimal ADDI CPU

Requirements:

* PC exists
* instruction fetch works
* decoder recognizes ADDI
* register file exists
* immediate generation works
* ALU can perform addition
* writeback works
* PC advances by 4
* `addi x10, x0, 1` passes

Commit after completion.

Suggested commit:

```text
feat: execute first rv64i addi instruction
```

---

## SC-02 — ALU register instructions

Implement and test RV64I register-register ALU instructions.

Commit after tests pass.

---

## SC-03 — Immediate ALU instructions

Implement and test immediate ALU instructions.

Commit after tests pass.

---

## SC-04 — LUI and AUIPC

Implement and test upper-immediate instructions.

Commit after tests pass.

---

## SC-05 — Branch and jump instructions

Implement and test branches, JAL, and JALR.

Commit after tests pass.

---

## SC-06 — Load/store

Implement and test RV64I memory instructions.

Commit after tests pass.

---

## SC-07 — RV64 word operations

Implement and test RV64-specific W instructions.

Commit after tests pass.

---

## SC-08 — Complete RV64I regression

Requirements:

* supported RV64I instruction tests pass
* regression suite exists
* illegal/unimplemented opcode behavior is visible in simulation
* no Verilator lint errors that indicate functional issues
* code is reasonably documented

Commit:

```text
feat: complete single-cycle rv64i cpu
```

Tagging the milestone is encouraged:

```bash
git tag single-cycle-rv64i
```

---

# Pipeline Phase

Do not begin pipeline implementation until the single-cycle RV64I implementation passes regression tests.

The single-cycle CPU acts as a known-good architectural reference.

Do not delete the single-cycle implementation.

Keep both implementations in the repository.

---

# Five-Stage Pipeline

Use the classic five-stage structure:

```text
IF
ID
EX
MEM
WB
```

Use explicit pipeline registers:

```text
IF/ID
ID/EX
EX/MEM
MEM/WB
```

Implement the pipeline incrementally.

Do not attempt to implement forwarding, stalls, and branches simultaneously.

---

# Pipeline Milestones

## PL-00 — Pipeline skeleton

Create the five-stage datapath and pipeline registers.

Initially run simple independent instructions that do not create hazards.

Commit after basic execution works.

---

## PL-01 — Basic arithmetic pipeline

Support arithmetic instructions without dependencies.

Verify multiple instructions can exist in the pipeline simultaneously.

Commit after regression subset passes.

---

## PL-02 — Data forwarding

Implement forwarding paths required for common RAW dependencies.

Typical forwarding sources include:

```text
EX/MEM → EX
MEM/WB → EX
```

Tests must include dependency chains such as:

```asm
addi x1, x0, 1
addi x2, x1, 2
addi x3, x2, 3
```

Commit after forwarding tests pass.

---

## PL-03 — Load-use hazard

Implement load-use hazard detection.

Insert stalls or bubbles where forwarding cannot resolve the dependency.

Add focused tests.

Commit after completion.

---

## PL-04 — Control hazards

Implement branch and jump handling.

A simple static design is sufficient.

Do not implement branch prediction.

Correctly flush invalid younger instructions after a taken control-flow change.

Commit after branch/jump tests pass.

---

## PL-05 — Memory pipeline

Ensure loads and stores work correctly through pipeline stages.

Add load/store dependency tests.

Commit after completion.

---

## PL-06 — Full RV64I pipeline

Run the full RV64I regression suite against the pipelined implementation.

The pipelined CPU should produce the same architectural results as the single-cycle CPU.

Commit:

```text
feat: complete five-stage rv64i pipeline
```

Recommended tag:

```bash
git tag five-stage-rv64i
```

---

# Git Rules

Git history is part of the project deliverable.

Before beginning work, inspect:

```bash
git status
git log --oneline --decorate -n 10
```

Do not overwrite unrelated user changes.

Do not use destructive Git operations unless clearly necessary.

Avoid:

```bash
git reset --hard
git clean -fd
git checkout -- .
```

unless explicitly required and safe.

Each meaningful working milestone should produce a commit.

Before committing:

1. run Verilator build
2. run relevant tests
3. run regression tests when practical
4. inspect `git diff`
5. ensure generated build artifacts are not accidentally committed

Use concise conventional commit-style messages.

Examples:

```text
chore: bootstrap verilator simulation
feat: add rv64 register file
feat: implement rv64i branch instructions
test: add load sign-extension cases
fix: handle jalr target alignment
feat: add ex stage forwarding
fix: stall pipeline on load-use hazard
```

Never claim that a milestone works without actually running its tests.

---

# Documentation

Update documentation when architectural decisions change.

At minimum maintain:

```text
README.md
docs/architecture.md
```

The documentation should explain:

* current CPU architecture
* supported ISA subset
* simulation commands
* test commands
* current milestone
* known limitations

Keep documentation synchronized with the code.

---

# Debugging Policy

When a test fails:

Do not immediately rewrite large parts of the design.

First identify:

```text
current PC
current instruction
decoded opcode
rs1 value
rs2 value
immediate
ALU input
ALU output
memory access
writeback destination
writeback value
next PC
```

For the pipeline also inspect:

```text
IF/ID
ID/EX
EX/MEM
MEM/WB
stall
flush
forwarding selection
```

Fix the smallest root cause.

Then rerun regression tests.

---

# Autonomy Rules

The agent should continue working toward the current milestone without repeatedly asking for confirmation.

The agent may autonomously:

* create source files
* edit RTL
* create tests
* modify build scripts
* run Verilator
* inspect wave/debug output
* run Git status/diff/log
* create milestone commits
* refactor code when necessary for the current goal
* update documentation

The agent should not autonomously:

* expand project scope
* add peripherals
* add caches
* add branch prediction
* implement an operating system
* add unrelated dependencies
* rewrite the project in another HDL
* delete working architectural implementations
* rewrite published Git history

If there are multiple reasonable implementation choices, prefer the simplest design that clearly demonstrates the architecture.

---

# Agent Work Loop

When operating autonomously, repeatedly perform:

```text
inspect current repository state
        ↓
identify next unfinished milestone
        ↓
implement smallest useful step
        ↓
build
        ↓
test
        ↓
debug if needed
        ↓
run regression
        ↓
document meaningful changes
        ↓
git commit stable milestone
        ↓
continue
```

Stop only when:

* the requested milestone is complete, or
* a genuine external blocker prevents further progress, or
* proceeding would require expanding beyond the defined project scope.

Do not stop merely because one small subtask has been completed.

---

# Current Short-Term Definition of Done

The current short-term project is complete when all of the following are true:

1. A working single-cycle RV64I CPU exists.
2. RV64I instruction tests pass under Verilator.
3. The single-cycle design is preserved in Git history and source.
4. A five-stage RV64I pipeline exists.
5. Data hazards are correctly handled.
6. Required forwarding is implemented.
7. Load-use hazards stall correctly.
8. Branch/jump control hazards are flushed correctly.
9. The pipelined CPU passes the RV64I regression suite.
10. Major milestones are represented by meaningful Git commits.
11. The repository contains instructions for building and testing.
12. Cache, branch prediction, peripherals, privilege modes, and OS work have not yet been added.

After reaching this point, stop expanding functionality and report the state of the repository.

Future work will be planned separately.

