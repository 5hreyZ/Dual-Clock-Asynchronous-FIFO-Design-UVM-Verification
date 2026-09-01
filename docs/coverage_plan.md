# Verification & Functional Coverage Plan

## 1. Overview
The verification strategy for the Dual-Clock Asynchronous FIFO employs a metric-driven UVM 1.2 testbench with concurrent SystemVerilog Assertions (SVA) and functional coverage models to verify CDC safety, data integrity, and throughput under extreme corner cases.

---

## 2. Coverage Metrics & Targets

| Metric | Target | Description |
| :--- | :--- | :--- |
| **Functional Coverage** | **100%** | All defined covergroups, bins, and cross-coverage points hit |
| **Assertion Coverage** | **100%** | All safety and liveness SVA properties exercised |
| **Line Coverage** | **100%** | Every statement in RTL executed |
| **Toggle Coverage** | **100%** | Every bit toggled $0 \to 1$ and $1 \to 0$ |
| **Branch / Condition** | **100%** | All branch outcomes taken |

---

## 3. Covergroup Specification

### 3.1 Write Domain Covergroup (`cg_write_domain`)
- **`cp_wdata`**: Data values written to FIFO
  - `all_zeros`: `8h00all_ones8hFF`
  - `alt_aa`: `8hAAalt_558h55`
  - `walking_1s`: Single bit high walking across bus
  - `low_range` & `high_range`: Full distribution
- **`cp_wfull`**: Status of full flag during write operations
  - `not_full`: Normal write
  - `is_full`: Overflow write attempt
- **`cp_almost_full`**: Threshold transition point
- **`cp_wdelay`**: Inter-transaction write delay (0 cycles burst, 1-3 short, 4-10 sparse)
- **Cross Coverage**:
  - `cross_wdata_wfull`: Ensures extreme data patterns are attempted under full conditions
  - `cross_delay_full`: Ensures burst and sparse traffic reach full states

### 3.2 Read Domain Covergroup (`cg_read_domain`)
- **`cp_rdata`**: Data values read from FIFO
- **`cp_rempty`**: Status of empty flag during read operations
  - `not_empty`: Normal read
  - `is_empty`: Underflow read attempt
- **`cp_almost_empty`**: Threshold transition point
- **`cp_rdelay`**: Inter-transaction read delay
- **Cross Coverage**:
  - `cross_rdata_rempty`: Reads across empty states
  - `cross_delay_empty`: Burst and sparse reads down to empty

---

## 4. Test Suite Mapping

| Test Name | Targeted Scenarios | SVA & Coverage Validated |
| :--- | :--- | :--- |
| `fifo_sanity_test` | Basic sequential write then read | Reset recovery, basic pointers |
| `fifo_burst_test` | Zero-delay burst to full capacity (depth=16), followed by burst drain | Full flag, Empty flag, back-to-back timing |
| `fifo_concurrent_test` | Simultaneous push and pop traffic on independent clocks | CDC synchronization, FIFO throughput |
| `fifo_overflow_underflow_test` | Deliberate push on `wfull=1` and pop on `rempty=1` | Overflow & Underflow assertions |
| `fifo_clock_ratio_test` | Fast write (100MHz) / Slow read (33MHz) & Slow write (33MHz) / Fast read (133MHz) | Clock ratio robustness, almost full/empty |
| `fifo_random_stress_test` | 200+ randomized transactions with mixed patterns and delays | 100% functional coverage closure |
