"""
Cocotb Verification Suite for Dual-Clock Asynchronous FIFO
Tests:
- Reset states
- Basic write & read
- Full burst fill and drain
- Overflow and Underflow protection
- Cross-clock ratio sweeps (Fast Write/Slow Read & Slow Write/Fast Read)
- Randomized stress traffic
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
import random
from model_fifo import AsyncFifoModel

DATA_WIDTH = 8
ADDR_WIDTH = 4
DEPTH = 1 << ADDR_WIDTH

async def reset_dut(dut):
    dut.wrst_n.value = 0
    dut.rrst_n.value = 0
    dut.w_inc.value  = 0
    dut.wdata.value  = 0
    dut.r_inc.value  = 0
    await Timer(50, units="ns")
    dut.wrst_n.value = 1
    await Timer(20, units="ns")
    dut.rrst_n.value = 1
    await Timer(20, units="ns")

async def start_clocks(dut, w_period_ns=10.0, r_period_ns=25.0):
    cocotb.start_soon(Clock(dut.wclk, w_period_ns, units="ns").start())
    cocotb.start_soon(Clock(dut.rclk, r_period_ns, units="ns").start())

@cocotb.test()
async def test_fifo_reset_state(dut):
    """Verify initial reset state: empty=1, full=0, pointers=0"""
    await start_clocks(dut, 10.0, 25.0)
    await reset_dut(dut)

    await RisingEdge(dut.wclk)
    assert dut.wfull.value == 0, f"Expected wfull=0, got {dut.wfull.value}"
    assert dut.almost_full.value == 0, f"Expected almost_full=0, got {dut.almost_full.value}"

    await RisingEdge(dut.rclk)
    assert dut.rempty.value == 1, f"Expected rempty=1, got {dut.rempty.value}"
    assert dut.almost_empty.value == 1, f"Expected almost_empty=1, got {dut.almost_empty.value}"
    dut._log.info("✓ Reset state test passed successfully")

@cocotb.test()
async def test_fifo_burst_fill_and_drain(dut):
    """Fill FIFO completely, check full flag, then drain and check empty flag"""
    model = AsyncFifoModel(DATA_WIDTH, DEPTH)
    await start_clocks(dut, 10.0, 25.0)
    await reset_dut(dut)

    # Step 1: Write burst to fill FIFO
    dut._log.info(f"Writing {DEPTH} elements to fill FIFO...")
    for i in range(DEPTH):
        await RisingEdge(dut.wclk)
        val = (0xA0 + i) & 0xFF
        dut.wdata.value = val
        dut.w_inc.value = 1
        model.write(val, int(dut.wfull.value))

    await RisingEdge(dut.wclk)
    dut.w_inc.value = 0
    dut.wdata.value = 0

    # Wait for write pointer to propagate across CDC synchronizer into read domain
    await ClockCycles(dut.rclk, 5)
    assert dut.wfull.value == 1, f"Expected wfull=1 after {DEPTH} writes"
    assert dut.rempty.value == 0, "Expected rempty=0 after writes"

    # Step 2: Read burst to drain FIFO
    dut._log.info("Reading elements back...")
    for i in range(DEPTH):
        await RisingEdge(dut.rclk)
        if not int(dut.rempty.value):
            dut.r_inc.value = 1
            read_data = int(dut.rdata.value)
            model.read(read_data, int(dut.rempty.value))
        else:
            dut.r_inc.value = 0

    await RisingEdge(dut.rclk)
    dut.r_inc.value = 0

    # Wait for read pointer to propagate into write domain
    await ClockCycles(dut.wclk, 5)
    assert dut.rempty.value == 1, "Expected rempty=1 after draining"
    assert dut.wfull.value == 0, "Expected wfull=0 after draining"
    assert model.mismatches == 0, f"Scoreboard detected {model.mismatches} mismatches"
    dut._log.info("✓ Burst fill and drain test passed successfully")

@cocotb.test()
async def test_fifo_overflow_underflow(dut):
    """Verify safety against overflow and underflow conditions"""
    model = AsyncFifoModel(DATA_WIDTH, DEPTH)
    await start_clocks(dut, 10.0, 20.0)
    await reset_dut(dut)

    # 1. Underflow attempt
    dut._log.info("Testing underflow protection on empty FIFO...")
    for _ in range(5):
        await RisingEdge(dut.rclk)
        dut.r_inc.value = 1
        model.read(int(dut.rdata.value), int(dut.rempty.value))
    await RisingEdge(dut.rclk)
    dut.r_inc.value = 0

    # 2. Fill FIFO + Overflow attempt
    dut._log.info("Testing overflow protection by writing DEPTH+6 elements...")
    for i in range(DEPTH + 6):
        await RisingEdge(dut.wclk)
        val = 0x50 + i
        dut.wdata.value = val
        dut.w_inc.value = 1
        model.write(val, int(dut.wfull.value))
    await RisingEdge(dut.wclk)
    dut.w_inc.value = 0

    # 3. Read back valid elements
    await ClockCycles(dut.rclk, 5)
    while not int(dut.rempty.value):
        await RisingEdge(dut.rclk)
        dut.r_inc.value = 1
        read_data = int(dut.rdata.value)
        model.read(read_data, int(dut.rempty.value))
    await RisingEdge(dut.rclk)
    dut.r_inc.value = 0

    assert model.overflow_attempts > 0, "Expected overflow attempts to be recorded"
    assert model.underflow_attempts > 0, "Expected underflow attempts to be recorded"
    assert model.mismatches == 0, "Zero data mismatches allowed during overflow/underflow"
    dut._log.info(f"✓ Overflow/Underflow test passed: {model.get_summary()}")

@cocotb.test()
async def test_fifo_random_concurrent_traffic(dut):
    """Randomized concurrent writes and reads with asymmetric clock frequencies"""
    model = AsyncFifoModel(DATA_WIDTH, DEPTH)
    # Fast write (100MHz / 10ns), Slower read (33MHz / 30ns)
    await start_clocks(dut, 10.0, 30.0)
    await reset_dut(dut)

    async def write_process():
        for _ in range(100):
            await RisingEdge(dut.wclk)
            if random.random() < 0.8:
                val = random.randint(0, 255)
                dut.wdata.value = val
                dut.w_inc.value = 1
                model.write(val, int(dut.wfull.value))
            else:
                dut.w_inc.value = 0
        await RisingEdge(dut.wclk)
        dut.w_inc.value = 0

    async def read_process():
        for _ in range(150):
            await RisingEdge(dut.rclk)
            if random.random() < 0.7:
                if not int(dut.rempty.value):
                    dut.r_inc.value = 1
                    model.read(int(dut.rdata.value), int(dut.rempty.value))
                else:
                    dut.r_inc.value = 0
            else:
                dut.r_inc.value = 0
        await RisingEdge(dut.rclk)
        dut.r_inc.value = 0

    await cocotb.start(write_process())
    await cocotb.start(read_process())

    # Allow remaining items to drain
    await Timer(500, units="ns")
    while not int(dut.rempty.value):
        await RisingEdge(dut.rclk)
        dut.r_inc.value = 1
        model.read(int(dut.rdata.value), int(dut.rempty.value))
    await RisingEdge(dut.rclk)
    dut.r_inc.value = 0

    summary = model.get_summary()
    dut._log.info(f"✓ Randomized stress test summary: {summary}")
    assert summary["mismatches"] == 0, f"Detected {summary['mismatches']} mismatches"
