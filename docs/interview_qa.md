# Top 15 Technical Interview Questions & Answers: Dual-Clock Async FIFO & CDC

### Q1: What is metastability, and why does it occur in asynchronous FIFOs?
**Answer:** Metastability occurs when setup ($t_{su}$) or hold ($t_h$) times of a flip-flop are violated, causing its output voltage to hover between valid logic levels ($V_{IL}$ and $V_{IH}$) for an indeterminate duration. In an asynchronous FIFO, the write and read clocks have no fixed phase relationship; therefore, pointer comparisons crossing clock domains will inevitably violate setup/hold times without synchronization.

---

### Q2: Why cannot we pass binary pointers across clock domains using 2-FF synchronizers?
**Answer:** Binary counters frequently toggle multiple bits simultaneously (e.g., $0111_2 \to 1000_2$ changes 4 bits). Due to physical silicon layout and clock skew, destination flip-flops will sample transitions at slightly different picosecond offsets, observing intermediate, corrupt binary values (e.g., $0000_2$ or $1111_2$). This causes false empty/full assertions or severe data corruption.

---

### Q3: Why is Gray code used for pointer domain crossing?
**Answer:** Gray code has a Hamming distance of 1 between consecutive values ($d_H = 1$), meaning **only one bit changes per clock cycle**. Even if that transitioning bit enters metastability, the destination synchronizer will resolve to either the previous pointer value or the new pointer value—both of which are valid and safe states.

---

### Q4: Why do we invert the MSB and 2nd MSB (MSB-1) to detect the Full condition in Gray code?
**Answer:** A FIFO is full when the write pointer has wrapped around once and reached the same physical memory address as the read pointer. 
In binary, $W = R + 2^n$, meaning the MSB is inverted and lower $n$ bits match. 
In Gray code, due to the reflection symmetry of the code, when the pointer wraps past the midpoint, the second MSB is also inverted relative to the first half of the sequence. Therefore, Gray code Full requires:
$$\text{wptr\_gray} == \{\sim rptr\_gray[n:n-1], rptr\_gray[n-2:0]\}$$

---

### Q5: Why is the Asynchronous FIFO design "pessimistic" (fail-safe by design)?
**Answer:** 
- The write domain compares the current write pointer against a **2-cycle delayed** read pointer. Hence, the write domain may perceive the FIFO as full even after data has just been read, temporarily withholding writes. It will **never overflow**.
- The read domain compares the current read pointer against a **2-cycle delayed** write pointer. Hence, the read domain may perceive the FIFO as empty even after data has just been written. It will **never underflow**.

---

### Q6: What synthesis attributes are needed on synchronizer flip-flops and why?
**Answer:** 
- `(* ASYNC_REG = "TRUE" *)` (Xilinx/Vivado) or `(* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)` (Intel/Quartus).
- `(* dont_touch = "true" *)` to prevent synthesis optimization (e.g., merging duplicate registers or retiming across domains).
- These attributes instruct P&R tools to place the synchronizer flip-flops in the same slice/CLB close together to minimize wire delay, maximize settling time $t_{\text{resolve}}$, and maximize MTBF.

---

### Q7: What is the purpose of the extra $(n+1)$-th bit in the address pointer?
**Answer:** For an $N = 2^n$ deep FIFO, an $n$-bit pointer cannot distinguish between **Full** and **Empty** because in both cases $waddr == raddr$. Adding the $(n+1)$-th MSB allows tracking wrap-arounds:
- If $W_{\text{MSB}} == R_{\text{MSB}}$ and $W_{\text{addr}} == R_{\text{addr}} \implies$ **Empty**.
- If $W_{\text{MSB}} \ne R_{\text{MSB}}$ and $W_{\text{addr}} == R_{\text{addr}} \implies$ **Full**.

---

### Q8: Can we design an Asynchronous FIFO of non-power-of-2 depth (e.g., Depth = 10)?
**Answer:** Standard Gray code relies on power-of-2 rollover symmetry so that transitioning from $(2^n - 1) \to 0$ changes only 1 bit. In a non-power-of-2 depth (e.g. 10), wrapping from 9 to 0 would change multiple bits, violating the 1-bit Gray code rule. To handle odd or non-power-of-2 depths, one must use truncated/symmetric Gray codes (e.g., choosing a symmetric range around the center of a $2^n$ sequence) or use an asynchronous credit-based handshake.

---

### Q9: What happens if the write clock is 100x faster than the read clock?
**Answer:** Multiple Gray code transitions will occur within a single read clock period. The read synchronizer will sample a pointer value that has advanced by multiple steps. However, because Gray code incremented monotonically, the sampled value is still a valid pointer from an earlier write cycle. The FIFO maintains correct operation without data loss (though `wfull` will assert quickly).

---

### Q10: Why should Gray-coded pointers never be generated with combinational logic before synchronization?
**Answer:** Combinational logic contains static glitches (hazards). If glitches cross into the synchronizer, the synchronizer may capture a spurious pulse as a valid transition, resulting in multi-bit corruptions. Gray pointers must always be **registered directly from flip-flop outputs** before crossing domains.

---

### Q11: How do you verify an Asynchronous FIFO in UVM without race conditions?
**Answer:** Using SystemVerilog **clocking blocks** with input/output skews (`default input #1step output #1ns;`). Clocking blocks sample signals in the Preponed region and drive in the Observed/NBA region, completely eliminating testbench vs DUT race conditions across multiple clock domains.

---

### Q12: How does the UVM Scoreboard handle cross-domain latency?
**Answer:** The scoreboard uses a reference queue (`expected_queue[$]`). When a write transaction occurs, the transaction is cloned and pushed onto the queue. When a read occurs, the data is popped and checked for equality. In-flight transactions are tracked using timestamps to calculate minimum, maximum, and average cross-clock transfer latency.

---

### Q13: What SVA assertions are essential for an Async FIFO?
**Answer:**
1. **Gray Code Hamming Distance Assertion:** Ensure Gray pointer changes by at most 1 bit per clock (`$countones(ptr ^ $past(ptr)) <= 1`).
2. **No-Overflow Invariant:** `w_inc && wfull |=> (wptr == $past(wptr))`.
3. **No-Underflow Invariant:** `r_inc && rempty |=> (rptr == $past(rptr))`.
4. **Reset State Invariants:** `rempty == 1` and `wfull == 0` during/after reset.

---

### Q14: How do you calculate almost-full and almost-empty thresholds in Gray code?
**Answer:** Since Gray codes cannot be directly subtracted mathematically to find distance, the synchronized Gray pointer is converted back to binary in the local clock domain. The local binary pointer is then subtracted from the synchronized binary pointer ($w_{\text{occupancy}} = wptr_{\text{bin}} - rptr_{\text{bin, sync}}$) to compute exact occupancy and compare against the threshold.

---

### Q15: How do you achieve 100% functional coverage in CDC verification?
**Answer:** By defining covergroups that cross:
1. Corner data patterns (0x00, 0xFF, 0xAA, walking 1s/0s).
2. FIFO states (Empty, Almost Empty, Mid, Almost Full, Full, Overflow attempts, Underflow attempts).
3. Clock frequency ratios (Fast write / Slow read, Slow write / Fast read, Jittered clocks).
4. Burst vs back-to-back vs sparse timing delays.
