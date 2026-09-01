# Clock Domain Crossing (CDC) & Metastability Analysis

This document details the architectural principles, mathematical foundations, and Clock Domain Crossing (CDC) considerations implemented in the **Dual-Clock Asynchronous FIFO**.

---

## 1. The CDC Problem: Metastability

When a digital signal generated in one clock domain (e.g., `wclk`) is sampled by a flip-flop in an asynchronous clock domain (e.g., `rclk`), the setup time ($t_{su}$) or hold time ($t_h$) of the destination flip-flop may be violated.

```
       Source Data (wclk) -----\\
                                \\----> [ D    Q ] ----> Destination Domain (rclk)
       Dest Clock  (rclk) ------------> [ >      ]
```

When a timing violation occurs:
- The flip-flop output may enter a **metastable state**, hovering between valid logic levels ($V_{IL}$ and $V_{IH}$) for an non-deterministic duration before settling to either `0` or `1`.
- If downstream combinational logic samples this metastable state, it can lead to logic corruption, illegal FSM transitions, and system crashes.

### Mean Time Between Failures (MTBF)
The reliability of a synchronizer is quantified by the Mean Time Between Failures:

$$\text{MTBF} = \frac{e^{\frac{t_{\text{resolve}}}{\tau}}}{T_0 \cdot f_{\text{clk}} \cdot f_{\text{data}}}$$

Where:
- $t_{\text{resolve}} = T_{\text{clk}} - t_{\text{cq}} - t_{\text{su}}$ is the available settling time.
- $\tau$ and $T_0$ are process technology constants.
- $f_{\text{clk}}$ is the receiving clock frequency.
- $f_{\text{data}}$ is the frequency of data transitions.

By cascading two flip-flops (2-FF synchronizer), $t_{\text{resolve}}$ increases by a full clock cycle, increasing MTBF by orders of magnitude (typically > 1,000,000 years for modern ASIC/FPGA nodes).

---

## 2. Multi-Bit CDC Hazard: Why Binary Pointers Fail

A fundamental rule of CDC design: **Never synchronize multi-bit signals across clock domains using independent 2-FF synchronizers if multiple bits can transition simultaneously.**

Consider a binary pointer incrementing from `3` (`0011_2`) to `4` (`0100_2`):
- 3 bits transition at the exact same moment ($0 \to 1, 1 \to 0, 1 \to 0$).
- Due to slight physical routing skew in silicon, the destination synchronizers will sample the bits at slightly different picosecond offsets.
- The sampled value could transiently be `0000`, `0001`, `0010`, `0111`, etc. (any intermediate combination), resulting in catastrophic pointer corruption.

---

## 3. The Solution: Gray-Coded Pointers

A **Gray code** is a cyclic binary numeral system where two successive values differ in **only one bit position** (Hamming distance $d_H = 1$).

### Binary to Gray Code Conversion
$$G[N] = B[N]$$
$$G[i] = B[i+1] \oplus B[i] \quad \text{for } 0 \le i < N$$
In SystemVerilog:
```systemverilog
assign gray_ptr = (bin_ptr >> 1) ^ bin_ptr;
```

### Gray to Binary Conversion
$$B[N] = G[N]$$
$$B[i] = B[i+1] \oplus G[i] \quad \text{for } N-1 \ge i \ge 0$$
In SystemVerilog:
```systemverilog
always_comb begin
    bin_ptr[N] = gray_ptr[N];
    for (int i = N - 1; i >= 0; i--) begin
        bin_ptr[i] = bin_ptr[i+1] ^ gray_ptr[i];
    end
end
```

### Why Gray Code Solves the CDC Problem:
Because only 1 bit ever changes at a time:
- Even if the destination clock edge occurs at the exact moment that bit transitions and the synchronizer experiences metastability, the settled outcome can only be either:
  1. The **old pointer value** (as if the transition hasn\x27t happened yet).
  2. The **new pointer value** (the transition registered).
- In either case, the pointer value is **always valid**, and no illegal intermediate state can ever be observed.

---

## 4. Full and Empty Condition Generation

An $N$-deep FIFO requires an $(n+1)$-bit pointer (where $2^n = N$) to distinguish between **completely empty** and **completely full** states.

### Empty Condition (Read Domain)
The FIFO is empty when the read pointer catches up with the write pointer:
$$\text{rempty} \iff \mathbf{rptr\_gray\_next == wptr\_gray\_sync}$$

### Full Condition (Write Domain)
The FIFO is full when the write pointer has wrapped around once ($2^n$ entries ahead) and reached the same memory address as the read pointer.

Because of the reflection symmetry of Gray codes, when the binary counter wraps around ($B_{\text{MSB}} \ne B_{\text{MSB, dest}}$):
- The MSB is inverted.
- The 2nd MSB (bit $n-1$) is also inverted.
- All remaining lower bits ($n-2$ down to $0$) match identically.

$$\text{wfull} \iff \mathbf{wptr\_gray\_next == \{\sim rptr\_gray\_sync[n:n-1], rptr\_gray\_sync[n-2:0]\}}$$

---

## 5. Pessimistic Flag Guarantees (Safe by Construction)

Because pointer synchronization introduces a 2-cycle latency across domains:
- **Write Domain** sees a delayed read pointer $\implies$ `wfull` is asserted slightly **earlier** or remains asserted slightly longer than real-time. It may temporarily block writes when space was just freed, but it will **never overflow**.
- **Read Domain** sees a delayed write pointer $\implies$ `rempty` is asserted slightly **longer** than real-time. It may temporarily delay reading newly written data, but it will **never underflow**.

This property guarantees that the FIFO is **fail-safe by design**.

---

## 6. Synthesis & Physical Implementation Attributes

To ensure EDA synthesis and P&R tools do not optimize away synchronizer flip-flops or place them on opposite corners of the die:

```systemverilog
(* ASYNC_REG = "TRUE" *)                                                          // Vivado CDC constraint
(* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *) // Quartus constraint
(* dont_touch = "true" *)                                                         // Generic synthesis keep
logic [WIDTH-1:0] sync_regs [STAGES-1:0];
```
