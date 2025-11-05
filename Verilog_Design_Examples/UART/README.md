# UART (Universal Asynchronous Receiver/Transmitter)

## 🧭 Overview

This project implements a simple UART **transmitter** and **receiver** pair in **Verilog HDL**.  
It follows the classic UART framing format:

> **1 start bit (0)** → **8 data bits (LSB first)** → **1 stop bit (1)**

The `CLKS_PER_BIT` parameter defines how many system clock cycles correspond to one UART bit period:

> CLKS_PER_BIT = Frequency of CLK / Baud Rate

**Example:**  
If `f_clk = 25 MHz` and `baud_rate = 115200`, then  
`CLKS_PER_BIT ≈ 25,000,000 / 115,200 ≈ 217`.

*  **Note / Credit:**  
> The UART transmitter and receiver modules are authored by **Pham Hoai Luan**.  
> These modules are reused here with full author attribution.

---

## 📁 Project Structure

| File | Description |
|------|--------------|
| `transmitter.v` | UART transmitter core (1 start, 8 data bits LSB first, 1 stop). |
| `receiver.v` | UART receiver core with synchronizer, start-bit detection, and data sampling. |

---

## 📤 Module: `transmitter.v`

### Parameters
- `CLKS_PER_BIT` *(default: 217)* — number of system clock cycles per UART bit.

### Ports
| Name | Direction | Width | Description |
|------|------------|--------|-------------|
| `CLK` | input | 1 | System clock. |
| `Tx_DV_in` | input | 1 | Data-valid pulse to start transmission (1 clock wide). |
| `Tx_Byte_in` | input | 8 | Byte to transmit (latched on `Tx_DV_in`). |
| `Tx_Active_out` | output | 1 | Asserted while transmitter is busy. |
| `Tx_out` | output | 1 | Serial TX line (idle = 1). |
| `Tx_Done_out` | output | 1 | Pulse (1 clock) when transmission completes. |

### Behavior Summary
- Finite State Machine (FSM):  
  **IDLE → START → DATA (8 bits, LSB first) → STOP → CLEANUP**
- In **IDLE**, when `Tx_DV_in` is asserted, the byte is latched and transmission begins.
- Each bit is held on `Tx_out` for exactly `CLKS_PER_BIT` cycles.
- `Tx_Done_out` pulses for **1 clock** at the end of transmission.

### Notes
- `Tx_out` idle level = **1**.  
- Use `Tx_Active_out` to check if the transmitter is busy.

---

## 📤 Module: `receiver.v`

### Purpose
Deserializes asynchronous serial input on `Rx_in` into an 8-bit parallel byte (`Rx_Byte_out`)  
and asserts a one-clock pulse (`Rx_DV_out`) when a valid byte is received.

### Parameters
- `CLKS_PER_BIT` *(default: 217)* — number of system clock cycles per UART bit.

### Ports
| Name | Direction | Width | Description |
|------|------------|--------|-------------|
| `CLK` | input | 1 | System clock (sampling domain). |
| `Rx_in` | input | 1 | Serial RX line (asynchronous). |
| `Rx_DV_out` | output | 1 | One-clock pulse when a byte is received. |
| `Rx_Byte_out` | output | 8 | Received byte (LSB first). |

### Key Implementation Details

#### 1. Two-Stage Synchronizer
Since `Rx_in` is asynchronous, it passes through a two-flop synchronizer to avoid metastability:
```verilog
Rx_Data_R_r <= Rx_in;
Rx_Data_r   <= Rx_Data_R_r;
