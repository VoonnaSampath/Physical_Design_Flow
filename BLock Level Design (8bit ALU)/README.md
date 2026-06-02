# Block Level Design: 8-bit ALU

This directory contains the block-level design files for the 8-bit ALU flow. It is organized around RTL design, simulation/debug, synthesis, constraints, and physical implementation handoff.

This README is intended to act as the index for the block-level design folder. The folder structure will be updated as additional flow directories are added.

## Table of Contents

- [Folder Structure](#folder-structure)
- [Folder Contents](#folder-contents)
- [VCS Simulation Flow](#vcs-simulation-flow)
- [Verdi Debug Flow](#verdi-debug-flow)
- [Design Compiler Synthesis Flow](#design-compiler-synthesis-flow)
- [ICC2 Physical Implementation Flow](#icc2-physical-implementation-flow)
- [Update Notes](#update-notes)

## Folder Structure

Current and planned block-level structure:

```text
BLock Level Design (8bit ALU)/
├── README.md
├── rtl/
│   ├── alu_8bit.v
│   └── tb_alu_8bit.v
├── CONSTRAINTS/
│   └── alu_8bit.sdc
├── VCS_8bit/
│   └── README.md
├── VERDI_8bit/
│   └── README.md
├── DC_8bit/
│   ├── README.md
│   ├── run_dc.tcl
│   ├── rm_setup/
│   └── Reports/
└── ICCII_8bit/
    ├── README.md
    ├── scripts/
    └── Reports/
```

Note: `VCS_8bit/` and `VERDI_8bit/` are included here as expected future work locations. Add or update these folders as the flow grows.

## Folder Contents

| Folder | Contents | README |
| --- | --- | --- |
| [`rtl/`](rtl/) | RTL source and testbench files for the 8-bit ALU. Current files include `alu_8bit.v` and `tb_alu_8bit.v`. | Add `rtl/README.md` if RTL notes are needed later. |
| [`CONSTRAINTS/`](CONSTRAINTS/) | Synopsys Design Constraints for the block. Current file: `alu_8bit.sdc`. | Add `CONSTRAINTS/README.md` if constraint notes are needed later. |
| `VCS_8bit/` | Planned VCS simulation flow directory for compiling and running the ALU testbench. | Planned: `VCS_8bit/README.md`. |
| `VERDI_8bit/` | Planned Verdi debug flow directory for waveform viewing and simulation debug. | Planned: `VERDI_8bit/README.md`. |
| [`DC_8bit/`](DC_8bit/) | Design Compiler synthesis flow, setup files, generated reports, and synthesis work record. | [`DC_8bit/README.md`](DC_8bit/README.md) |
| [`ICCII_8bit/`](ICCII_8bit/) | ICC2 physical implementation scripts and report directory for design planning, placement, CTS, routing, and report extraction. | [`ICCII_8bit/README.md`](ICCII_8bit/README.md) |

## VCS Simulation Flow

The VCS flow is used to compile the RTL and testbench, run simulation, and generate simulation output for functional verification.

Expected inputs:

```text
rtl/alu_8bit.v
rtl/tb_alu_8bit.v
```

Recommended future location:

```text
VCS_8bit/
```

Typical VCS flow steps:

1. Compile `alu_8bit.v` with `tb_alu_8bit.v`.
2. Run the generated simulation executable.
3. Capture the simulation log.
4. Generate waveform output if enabled by the testbench.
5. Document pass/fail behavior and any observed mismatches.

Example command template:

```sh
vcs -full64 -sverilog ../rtl/alu_8bit.v ../rtl/tb_alu_8bit.v -o simv
./simv
```

When the `VCS_8bit/` folder is added, place its detailed instructions in:

```text
VCS_8bit/README.md
```

## Verdi Debug Flow

The Verdi flow is used to inspect simulation waveforms, debug RTL behavior, and trace signal activity across the ALU design and testbench.

Expected inputs:

```text
rtl/alu_8bit.v
rtl/tb_alu_8bit.v
```

Recommended future location:

```text
VERDI_8bit/
```

Typical Verdi flow steps:

1. Generate a waveform database from the VCS simulation.
2. Launch Verdi with the RTL, testbench, and waveform database.
3. Add important ALU signals to the waveform window.
4. Inspect input operands, opcode/control signals, result outputs, flags, reset behavior, and clocked register updates.
5. Document debug observations in the Verdi flow README.

Example command template:

```sh
verdi -sv ../rtl/alu_8bit.v ../rtl/tb_alu_8bit.v -ssf waveform.fsdb
```

When the `VERDI_8bit/` folder is added, place its detailed instructions in:

```text
VERDI_8bit/README.md
```

## Design Compiler Synthesis Flow

The Design Compiler synthesis work is recorded in:

```text
DC_8bit/README.md
```

Use this flow to synthesize the RTL into a mapped gate-level design using `run_dc.tcl`.

Main files:

```text
DC_8bit/run_dc.tcl
DC_8bit/rm_setup/common_setup.tcl
DC_8bit/rm_setup/dc_setup.tcl
DC_8bit/rm_setup/dc_setup_filenames.tcl
CONSTRAINTS/alu_8bit.sdc
rtl/alu_8bit.v
```

README link:

```text
DC_8bit/README.md
```

## ICC2 Physical Implementation Flow

The ICC2 flow directory contains physical implementation scripts for the block-level ALU.

Current script location:

```text
ICCII_8bit/scripts/
```

Current scripts:

```text
ICCII_8bit/scripts/mmmc_script.tcl
ICCII_8bit/scripts/design_planning.tcl
ICCII_8bit/scripts/placement.tcl
ICCII_8bit/scripts/cts.tcl
ICCII_8bit/scripts/routing.tcl
ICCII_8bit/scripts/extracting_reports.tcl
```

The ICC2 physical implementation work is recorded in:

```text
ICCII_8bit/README.md
```

## Update Notes

When updating the folder structure later:

- Add new flow folders to the tree in [Folder Structure](#folder-structure).
- Add each new folder to the [Folder Contents](#folder-contents) table.
- Link each flow folder to its own README when available.
- Keep this file as the high-level index and keep detailed tool instructions inside each flow-specific README.
