# Data Transfer FSM

## Overview

This project implements a Finite State Machine (FSM) in Verilog to transfer data between two SRAMs of different sizes. Specifically, it transfers data from an input SRAM (RAM_IN) with a configuration of 8 bits x 32 locations to an output SRAM (RAM_OUT) with a configuration of 16 bits x 16 locations. The FSM reads 8-bit bytes from RAM_IN, combines two consecutive bytes into a 16-bit word, and writes this word into RAM_OUT.

## Project Structure

-   `ram_dp_async_read.v`: A dual-port RAM module with synchronous write and asynchronous read capabilities. This module is used for both RAM_IN and RAM_OUT.
-   `top_fsm.v`: The top-level module containing the FSM logic for data transfer. It instantiates two `ram_dp_async_read` modules.
-   `tb_top_fsm.v`: The testbench for `top_fsm.v`, used to verify the FSM's functionality.

## Module Descriptions

### `ram_dp_async_read.v`

This module defines a generic dual-port RAM.

**Parameters:**
-   `WIDTH`: Data width of the RAM (default: 8).
-   `DEPTH`: Number of memory locations (default: 16).
-   `DEPTH_LOG`: Log2 of `DEPTH`, automatically calculated for address bus width.

**Ports:**
-   `clk`: Clock signal for synchronous write operations.
-   `we_n`: Write enable (active high).
-   `addr_wr`: Write address.
-   `addr_rd`: Read address.
-   `data_wr`: Data input for write operations.
-   `data_rd`: Data output for asynchronous read operations.

### `top_fsm.v`

This module implements the data transfer FSM.

**Functionality:**
The FSM orchestrates the transfer of 32 bytes from `RAM_IN` (8-bit wide, 32-depth) to `RAM_OUT` (16-bit wide, 16-depth). It reads two consecutive 8-bit bytes from `RAM_IN`, concatenates them into a 16-bit word (where the first byte read becomes the LSB and the second byte becomes the MSB), and writes this 16-bit word into `RAM_OUT`.

**FSM States:**
The FSM operates in four states:

1.  **IDLE**:
    -   Initial state.
    -   Waits for `opmode_in` to be high (1'b1) to start the data transfer.
    -   If `opmode_in` is low (1'b0), it remains in IDLE.
2.  **READ_BYTE0**:
    -   Reads the first 8-bit byte from `RAM_IN` at `ram_pointer` address.
    -   Stores the byte in `read_byte0_buffer`.
    -   Increments `ram_pointer`.
    -   Transitions to `READ_BYTE1`.
3.  **READ_BYTE1**:
    -   Reads the second 8-bit byte from `RAM_IN` at the new `ram_pointer` address.
    -   The byte previously in `read_byte0_buffer` is moved to `read_byte1_buffer`, and the new byte is stored in `read_byte0_buffer`.
    -   Increments `ram_pointer`.
    -   Transitions to `WRITE_BYTE12`.
4.  **WRITE_BYTE12**:
    -   Combines `read_byte1_buffer` (MSB) and `read_byte0_buffer` (LSB) into a 16-bit word.
    -   Writes this 16-bit word to `RAM_OUT` at address `ram_pointer >> 1`.
    -   If `done_out` is high (meaning all 32 bytes have been processed), transitions back to `IDLE`.
    -   Otherwise, transitions back to `READ_BYTE0` to process the next pair of bytes.

**Control Signals:**
-   `opmode_in`: Input signal to initiate the data transfer (active high).
-   `done_out`: Output signal indicating the completion of the data transfer (active high, set when `ram_pointer` reaches 31).

### `tb_top_fsm.v`

This testbench verifies the functionality of the `top_fsm` module.

**Test Scenario:**
1.  Initializes the FSM with a reset.
2.  Performs two loops of data transfer:
    -   **Write Phase**: Fills `RAM_IN` with 32 bytes of a specific data pattern. The pattern is `((i % 2) << 7) + i + loop_no`.
    -   **Transfer Trigger**: Sets `opmode_in` high for one clock cycle to start the FSM.
    -   **Wait for Completion**: Waits until `done_out` from the FSM is asserted.
    -   **Read and Verify Phase**: Reads 16 words from `RAM_OUT` and compares them against expected values. The expected 16-bit word is formed by concatenating two consecutive 8-bit values from the input pattern: `{byte_at_i+1, byte_at_i}`.
3.  Reports the number of tests, successful comparisons, and errors.

