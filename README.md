# ⚙️ ALU-8 — 8-Bit ALU in Verilog (Structural Design)

A **full structural implementation** of an **8-bit Arithmetic Logic Unit (ALU)** in Verilog. The design is built bottom-up from primitive gate-level modules — full adder, multiplexers, and bitwise logic units — all wired together structurally with no behavioral shortcuts. A testbench is included to simulate and verify all 12 supported operations using Icarus Verilog.

---

## 📌 About

This project was built as a digital design assignment to demonstrate a **structurally designed 8-bit ALU** in Verilog. Rather than writing a single behavioral `always` block, every operation is implemented as its own module and connected through a 16-to-1 multiplexer selected by a 4-bit `AluOp` control signal. The ALU computes the result and outputs three status flags: `Zero`, `Negative`, and `Overflow`.

---

## 🛠️ How It Works

### Supported Operations

| AluOp | Operation | Description |
|-------|-----------|-------------|
| `0000` | `A + B` | 8-bit addition |
| `0001` | `B - A` | 8-bit subtraction (2's complement) |
| `0010` | `A + 1` | Increment A |
| `0101` | `A == B` | Equality check (returns 1 or 0) |
| `0110` | `B << 1` | Logical shift left |
| `0111` | `B >> 1` | Arithmetic shift right |
| `1000` | `NOT A` | Bitwise NOT |
| `1001` | `A AND B` | Bitwise AND |
| `1010` | `A OR B` | Bitwise OR |
| `1011` | `A NAND B` | Bitwise NAND |
| `1100` | `rotL A` | Rotate A left by 1 |
| `1101` | `rotR A` | Rotate A right by 1 |

### Status Flags

| Flag | Condition |
|------|-----------|
| `Zero` | Result == 0 |
| `Negative` | Result[7] == 1 (MSB set) |
| `Overflow` | Signed overflow detected for `+`, `-`, `inc` |

### Module Hierarchy

| Module | Description |
|--------|-------------|
| `full_adder` | 1-bit full adder: `{cout, sum} = a + b + cin` |
| `adder` | 8-bit ripple-carry adder using 8 chained full adders |
| `mux2to1` | 2-to-1 multiplexer (8-bit) |
| `mux4to1` | 4-to-1 multiplexer built from three `mux2to1` |
| `mux16to1` | 16-to-1 multiplexer built from five `mux4to1` |
| `and8` / `or8` / `not8` / `nand8` | Bitwise logic units |
| `inc8` | Increment by 1 using `adder` |
| `eq8` | Equality check using XNOR and AND reduction |
| `shl1` / `shr1` | Logical shift left / arithmetic shift right |
| `rotl1` / `rotr1` | Rotate left / rotate right by 1 bit |
| `ops` | Computes all 12 operations in parallel |
| `ALU_8` | Top-level ALU: wires `ops` → `mux16to1` → flags |
| `ALU_8_tb` | Testbench: exercises all operations with A=13, B=7 |

---

## 📁 Project Structure

```
alu-8-verilog/
│
├── src/
│   └── ALU_8.v             # Full ALU design + testbench in one file
├── data/
│   └── sample_runs.txt     # Expected simulation output for all 12 operations
├── README.md               # Project documentation
├── LICENSE                 # MIT License
└── .gitignore              # Ignores compiled simulation files
```

---

## ▶️ How to Run

### Prerequisites
- [Icarus Verilog](https://bleyer.org/icarus/) installed (`iverilog` and `vvp` on PATH)

### Compile
```bash
iverilog -o alu_sim src/ALU_8.v
```

### Simulate
```bash
vvp alu_sim
```

---

## 🖥️ Sample Output

With `A = 8'd13` (00001101) and `B = 8'd7` (00000111):

```
A + B    = 20,  Zero=0, Neg=0, Overflow=0
B - A    = -6,  Zero=0, Neg=1, Overflow=0
A + 1    = 14,  Zero=0, Neg=0, Overflow=0
A == B   = 00000000, Zero=1, Neg=0, Overflow=0
B <<< 1  = 00001110, Zero=0, Neg=0, Overflow=0
B >>> 1  = 00000011, Zero=0, Neg=0, Overflow=0
Rotate A left  = 00011010, Zero=0, Neg=0, Overflow=0
Rotate A right = 10000110, Zero=0, Neg=1, Overflow=0
NOT A    = 11110010, Zero=0, Neg=1, Overflow=0
A AND B  = 00000101, Zero=0, Neg=0, Overflow=0
A OR B   = 00001111, Zero=0, Neg=0, Overflow=0
A NAND B = 11111010, Zero=0, Neg=1, Overflow=0
```

---

## 🧠 Concepts Demonstrated

- **Structural Verilog design** — every module is built by wiring submodules, not behavioral `always` blocks
- **Ripple-carry adder** — 8 full adders chained bit-by-bit, carry propagates from LSB to MSB
- **2's complement subtraction** — `B - A` computed as `B + (~A + 1)` using the adder module
- **Multiplexer tree** — 16-to-1 MUX built hierarchically from 2-to-1 units; `AluOp` selects the result
- **Overflow detection** — sign-bit analysis for addition, subtraction, and increment
- **Arithmetic vs logical shift** — `shr1` preserves the sign bit (arithmetic); `shl1` fills with zero
- **Rotation** — `rotl1` and `rotr1` wrap the shifted-out bit back to the other end
- **Equality via XNOR** — bits are compared with XNOR then AND-reduced to a single flag
- **Parallel computation** — `ops` module computes all operations simultaneously; MUX selects output

---

## 📜 License

This project is open source and available under the [MIT License](LICENSE).
