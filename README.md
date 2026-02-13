# UVM-based-vedic-multiplier

## Overview
This project implements a **64-bit Vedic Multiplier** using a hierarchical design approach in **Verilog** and verifies it using a **UVM-based constrained-random verification environment**.

The multiplier is based on the **Urdhva-Tiryagbhyam (vertical and crosswise)** Vedic multiplication algorithm. The design is built hierarchically from **2×2 up to 64×64** multipliers.

A complete **UVM testbench** is developed including driver, monitor, sequencer, scoreboard, functional coverage, SVA assertions, and automated regression.

---

## Key Features

### RTL Design
- 64-bit Vedic multiplier in Verilog
- Hierarchical decomposition:
  - 64×64 → 32×32
  - 32×32 → 16×16
  - 16×16 → 8×8
  - 8×8 → 4×4
  - 4×4 → 2×2
- Combinational multiplier blocks
- Registered output (1-cycle latency)

---

### UVM Verification Environment
Complete SystemVerilog UVM testbench including:

- **Sequence Item**
  - Randomized 64-bit operands
  - Corner-case generation
  - Operand distribution control

- **Driver**
  - Synchronous stimulus to DUT

- **Monitor**
  - Samples DUT inputs and outputs
  - Handles 1-cycle latency alignment

- **Scoreboard**
  - Compares DUT output with reference model
  - Tracks pass/fail statistics

- **Functional Coverage**
  - Operand classes:
    - Zero
    - One
    - Max value
    - MSB-only
    - Alternating patterns
  - Magnitude bins
  - Cross coverage

- **Assertions (SVA)**
  - 1-cycle latency correctness check
  - X-propagation detection

- **Regression**
  - Automated multi-test execution

---

## Project Structure
tb
  ved_if.sv
  ved_assertions.sv
  ved_pkg.sv
  ved_tb_top.sv
  tests
    ved_test_basic.sv
    ved_test_corner.sv
    ved_test_random_cov.sv
  run
    compile_questa.do
    run_questa.do
    regress.sh
rtl
  vedic_64x64.sv   // your RTL (all modules)

---

## Verification Strategy

### Test Types

**1. Basic Test**
- Directed operand combinations
- Basic functionality check

**2. Corner Case Test**
- Zero operands
- Maximum operands
- Alternating bit patterns
- MSB-only values
- Boundary values

**3. Random Coverage Test**
- Constrained-random operands
- Coverage-driven stimulus
- Target: **>95% functional coverage**

---

## Reference Model

The scoreboard checks the DUT output against:
expected = a * b

Since the DUT output is registered, comparison uses:

---

## Assertions

Main SVA property:
result == $past(a) * $past(b)

This ensures:
- Correct multiplication
- Proper 1-cycle pipeline behavior
- No X propagation

---

## Simulation Instructions (QuestaSim Example)

### Step 1: Compile
vsim -c -do tb/run/compile_questa.do

### Step 2: Run Random Coverage Test
vsim -c -do tb/run/run_questa.do

### Step 3: Run Full Regression
cd tb/run
chmod +x regress.sh
./regress.sh

---

## Expected Results
- All tests pass with **zero mismatches**
- Functional coverage **>95%**
- No SVA assertion failures

---

## Tools Used
- Verilog / SystemVerilog
- UVM (Universal Verification Methodology)
- QuestaSim / ModelSim (or equivalent simulator)

---

## Resume-Ready Highlights
- Designed a hierarchical **64-bit Vedic multiplier** in Verilog.
- Developed a complete **UVM verification environment** with driver, monitor, sequencer, and scoreboard.
- Implemented **constrained-random testing**, functional coverage, and SVA assertions.
- Achieved **>95% functional coverage** using automated regression.

---

## Future Improvements
- Signed multiplier support
- Pipelined architecture
- Formal verification
- Synthesis and timing analysis
