# UVM Testbench Architecture

## 1. Verification Hierarchy

```mermaid
graph TD
    TB_TOP["tb_top (Dual Clock & Reset Generator)"]
    TB_TOP --> DUT["async_fifo (RTL DUT)"]
    TB_TOP --> BIND["fifo_bind -> fifo_sva"]
    TB_TOP --> VIF["fifo_if (Dual-Domain Interface)"]
    
    TB_TOP --> UVM_ROOT["UVM Test (e.g. fifo_random_stress_test)"]
    UVM_ROOT --> ENV["fifo_env"]
    
    ENV --> W_AGENT["fifo_write_agent (wclk domain)"]
    W_AGENT --> W_SQRE["fifo_write_sequencer"]
    W_AGENT --> W_DRV["fifo_write_driver"]
    W_AGENT --> W_MON["fifo_write_monitor"]
    
    ENV --> R_AGENT["fifo_read_agent (rclk domain)"]
    R_AGENT --> R_SQRE["fifo_read_sequencer"]
    R_AGENT --> R_DRV["fifo_read_driver"]
    R_AGENT --> R_MON["fifo_read_monitor"]
    
    ENV --> SCB["fifo_scoreboard (Golden Queue Reference Model)"]
    ENV --> COV["fifo_coverage (Functional Coverage Collector)"]
    
    W_MON -->|Analysis Port (w_item)| SCB
    W_MON -->|Analysis Port (w_item)| COV
    R_MON -->|Analysis Port (r_item)| SCB
    R_MON -->|Analysis Port (r_item)| COV
```

---

## 2. Component Descriptions

### 2.1 Interface (`fifo_if.sv`)
- Encapsulates separate `w_driver_cb` and `w_mon_cb` clocking blocks for the write clock domain (`wclk`).
- Encapsulates separate `r_driver_cb` and `r_mon_cb` clocking blocks for the read clock domain (`rclk`).
- Guarantees zero race conditions between UVM driving and DUT sampling.

### 2.2 Sequence Item (`fifo_item.sv`)
- Encapsulates randomized `data`, `op_type` (`OP_WRITE`, `OP_READ`, `OP_IDLE`), `delay`, and `pattern_type`.
- Includes timing metadata (`sim_time`) and status flags (`wfull`, `rempty`, `almost_full`, `almost_empty`).

### 2.3 Scoreboard (`fifo_scoreboard.sv`)
- Connects to write and read monitors via non-blocking TLM analysis implementations.
- Maintains an internal Golden Reference Queue `fifo_item expected_queue[$]`.
- Enforces strict in-order matching and flags data corruption, drops, duplicates, or out-of-order deliveries.
- Computes cross-clock transfer latency statistics (Min, Max, Average).

### 2.4 Functional Coverage Collector (`fifo_coverage.sv`)
- Samples covergroups on every transaction broadcast from the monitors.
- Tracks all data pattern corners, full/empty flag states, and delay distributions.
