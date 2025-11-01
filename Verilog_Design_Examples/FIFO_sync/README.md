# Synchronous FIFO (First-In, First-Out)

## Overview

This project implements a synchronous First-In, First-Out (FIFO) buffer in Verilog. The FIFO is designed to store and retrieve data in a sequential manner, where the first data element written into the buffer is the first one to be read out. It features configurable data width and depth, along with `empty` and `full` status flags.

## Project Structure

-   `FIFO_sync.v`: The main module implementing the synchronous FIFO logic.
-   `tb_FIFO_sync.v`: The testbench for `FIFO_sync.v`, used to verify its functionality through various scenarios.
-   `Vivado_simulation_Scenario_1.png`: Simulation waveform for Scenario 1 (basic write/read).
-   `Vivado_simulation_Scenario_2.png`: Simulation waveform for Scenario 2 (continuous write/read).
-   `Vivado_simulation_Scenario_3.png`: Simulation waveform for Scenario 3 (FIFO full condition).

## Module Description: `FIFO_sync.v`

This module defines a synchronous FIFO buffer.

**Parameters:**
-   `FIFO_DEPTH`: Defines the number of data elements the FIFO can store (default: 8).
-   `DATA_WIDTH`: Defines the bit width of each data element (default: 32).

**Ports:**
-   `clk`: Clock signal. All operations are synchronous to its positive edge.
-   `rst_n`: Asynchronous reset (active low). Resets pointers and `data_out`.
-   `cs`: Chip select (active high). Enables FIFO operations.
-   `wr_en`: Write enable (active high). When asserted, `data_in` is written to the FIFO.
-   `rd_en`: Read enable (active high). When asserted, data is read from the FIFO to `data_out`.
-   `data_in`: Input data to be written into the FIFO.
-   `data_out`: Output data read from the FIFO.
-   `empty`: Output flag, asserted when the FIFO is empty.
-   `full`: Output flag, asserted when the FIFO is full.

**Internal Logic:**
-   **Memory Array**: A `reg` array `fifo` stores the data.
-   **Pointers**: `write_pointer` and `read_pointer` are used to track the write and read locations within the `fifo` array. These pointers are `($clog2(FIFO_DEPTH) + 1)` bits wide, using an extra MSB to differentiate between empty and full conditions.
-   **Write Operation**: Data is written to `fifo[write_pointer[FIFO_DEPTH_LOG - 1 : 0]]` on the positive clock edge when `cs`, `wr_en` are high and the FIFO is not `full`. The `write_pointer` increments.
-   **Read Operation**: Data is read from `fifo[read_pointer[FIFO_DEPTH_LOG - 1 : 0]]` to `data_out` on the positive clock edge when `cs`, `rd_en` are high and the FIFO is not `empty`. The `read_pointer` increments.
-   **Empty Condition**: `empty` is asserted when `read_pointer` equals `write_pointer`.
-   **Full Condition**: `full` is asserted when the MSB of `read_pointer` is different from the MSB of `write_pointer`, but their lower bits are identical. This indicates that the pointers have wrapped around and are one position apart in the extended address space.

## Testbench Description: `tb_FIFO_sync.v`

This testbench verifies the functionality of the `fifo_sync` module by simulating various write and read operations.

**Test Scenarios:**

1.  **Scenario 1 (Basic Write/Read)**:
    -   Writes three distinct data values (1, 10, 100) into the FIFO.
    -   Performs four read operations to demonstrate data retrieval and the `empty` flag behavior.
2.  **Scenario 2 (Continuous Write/Read)**:
    -   Performs `FIFO_DEPTH` cycles of simultaneous write and read operations.
    -   Each cycle writes `2**i` and immediately reads a value, testing the FIFO's ability to handle continuous data flow without becoming full or empty.
3.  **Scenario 3 (FIFO Full and Overflow)**:
    -   Attempts to write `FIFO_DEPTH + 1` data values into the FIFO. This tests the `full` flag and ensures no data is written when the FIFO is full.
    -   Subsequently reads `FIFO_DEPTH` data values to empty the FIFO.
