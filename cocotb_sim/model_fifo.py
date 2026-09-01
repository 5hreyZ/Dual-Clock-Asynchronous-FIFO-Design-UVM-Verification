"""
Python Golden Reference Model for Asynchronous FIFO
Used in Cocotb simulation testbenches.
"""
from collections import deque
import logging

class AsyncFifoModel:
    def __init__(self, data_width=8, depth=16):
        self.data_width = data_width
        self.depth = depth
        self.queue = deque()
        self.total_writes = 0
        self.total_reads = 0
        self.overflow_attempts = 0
        self.underflow_attempts = 0
        self.matches = 0
        self.mismatches = 0
        self.logger = logging.getLogger("AsyncFifoModel")

    def write(self, data, wfull):
        if wfull:
            self.overflow_attempts += 1
            self.logger.info(f"[MODEL] Overflow write attempt blocked (data=0x{data:02X})")
            return False
        else:
            self.queue.append(data)
            self.total_writes += 1
            self.logger.debug(f"[MODEL] Write 0x{data:02X} | Occupancy={len(self.queue)}")
            return True

    def read(self, dut_data, rempty):
        if rempty:
            self.underflow_attempts += 1
            self.logger.info("[MODEL] Underflow read attempt blocked")
            return None
        else:
            if len(self.queue) == 0:
                self.mismatches += 1
                self.logger.error(f"[MODEL ERROR] DUT produced 0x{dut_data:02X} but reference queue was EMPTY!")
                return None
            expected = self.queue.popleft()
            self.total_reads += 1
            if expected == dut_data:
                self.matches += 1
                self.logger.debug(f"[MODEL MATCH] 0x{dut_data:02X} == 0x{expected:02X}")
            else:
                self.mismatches += 1
                self.logger.error(f"[MODEL MISMATCH] Expected 0x{expected:02X}, got 0x{dut_data:02X}")
            return expected

    def is_empty(self):
        return len(self.queue) == 0

    def is_full(self):
        return len(self.queue) >= self.depth

    def get_summary(self):
        return {
            "total_writes": self.total_writes,
            "total_reads": self.total_reads,
            "overflow_attempts": self.overflow_attempts,
            "underflow_attempts": self.underflow_attempts,
            "matches": self.matches,
            "mismatches": self.mismatches,
            "in_flight": len(self.queue)
        }
