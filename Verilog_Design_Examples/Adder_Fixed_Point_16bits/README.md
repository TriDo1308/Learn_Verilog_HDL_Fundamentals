# Adder Fixed Point 16 bits

## Overview

This project implements a **16-bit signed fixed-point adder IP** in Verilog, supporting **Q4.3 format** (1 sign bit, 4 integer bits, 3 fractional bits).  
Each operand is **16 bits**, received **byte-by-byte (2 bytes per operand)** via UART.  
The system uses **modular design** with UART I/O, input memory, FSM controller, datapath with saturation, and result transmission.  
All modules are integrated in a top-level IP core suitable for FPGA deployment.

## Project Structure

- `receiver.v`: UART receiver module, receives serial data and outputs valid 8-bit bytes.
- `Input_Memory.v`: Stores two 16-bit operands (A and B) by loading MSB and LSB separately from UART bytes.
- `Controller.v`: Finite State Machine (FSM) controlling the data flow: receives 4 bytes → compute → send 2-byte result.
- `Datapath.v`: Performs 16-bit signed fixed-point addition with saturation (±32767 / -32768).
- `transmitter.v`: UART transmitter module, sends the 16-bit result as two serial bytes (MSB first, then LSB).
- `Core.v`: Main processing module, connects all submodules and manages data/control signals.
- `Add_IP.v`: Top-level wrapper, instantiates the core and UART interface modules.

## Module Descriptions

### `receiver.v`

Implements a UART receiver using **oversampling** (`CLKS_PER_BIT = 217`).  
Detects start bit, samples 8 data bits (LSB first), verifies stop bit, and outputs valid byte.

**Ports:**
- `CLK`: System clock.
- `Rx_in`: UART serial input.
- `Rx_DV_out`: Data valid pulse (1 cycle).
- `Rx_Byte_out`: 8-bit received data.

### `Input_Memory.v`

Stores **two 16-bit operands** (`a_out`, `b_out`) by loading **MSB and LSB separately** via 4 enable signals.  
Controlled by `Controller.v` to handle byte-by-byte UART input.

**Ports:**
- `CLK`, `RST`: Clock and active-low reset.
- `Load_MSB_a_en_in`, `Load_LSB_a_en_in`: Load high/low byte of operand A.
- `Load_MSB_b_en_in`, `Load_LSB_b_en_in`: Load high/low byte of operand B.
- `Rx_Byte_in`: 8-bit data from receiver.
- `a_out`, `b_out`: 16-bit operands for computation.

### `Controller.v`

Implements a **4-state FSM** to manage the entire flow:
- **IDLE**: Wait for first byte.
- **LOAD**: Count 4 valid bytes → load MSB/LSB of A and B.
- **EXE**: Enable datapath computation.
- **SEND**: Send result in 2 bytes (MSB → LSB), wait for `Tx_Done`.

Uses counters (`load_counter_r`, `send_counter_r`) to track progress.

**Ports:**
- `CLK`, `RST`: Clock and reset.
- `Rx_Byte_in`, `Rx_DV_in`: From receiver.
- `Tx_Done_in`: From transmitter.
- `c_valid_in`: From datapath.
- Control outputs: `En_out`, `Load_*_en_out`, `Tx_DV_out`, `MLSB_SEL_Tx_Byte_out`.

### `Datapath.v`

Performs **16-bit signed fixed-point addition** (Q4.3 format) with **saturation**:
- `sum = a_in + b_in` (17-bit intermediate).
- Clamp to `±32767` if overflow.

**Ports:**
- `CLK`, `RST`: Clock and reset.
- `En_in`: Enable computation.
- `a_in`, `b_in`: 16-bit input operands.
- `c_out`: 16-bit result.
- `c_valid_out`: Result ready flag.

### `transmitter.v`

Implements a UART transmitter using FSM.  
Sends **start bit → 8 data bits (LSB first) → stop bit**.  
Outputs `Tx_Active_out` (active during transmission) and `Tx_Done_out` (pulse on completion).

**Ports:**
- `CLK`, `Tx_Byte_in`, `Tx_DV_in`: Clock, data, valid.
- `Tx_out`: UART serial output.
- `Tx_Active_out`: Transmission in progress.
- `Tx_Done_out`: Transmission complete.

### `Core.v`

Main processing core.  
Connects `Controller`, `Input_Memory`, and `Datapath`.  
Selects **MSB or LSB of `c_out`** for transmission using `MLSB_SEL_Tx_Byte_out`.

**Ports:**
- `CLK`, `RST`: Clock and reset.
- `Rx_Byte_in`, `Rx_DV_in`: From receiver.
- `Tx_Done_in`: From transmitter.
- `Tx_DV_out`, `Tx_Byte_out`: To transmitter.
- `c_out`: Debug output (MSB of result).

### `Add_IP.v`

Top-level wrapper.  
Instantiates `receiver`, `Core`, and `transmitter`.  
Connects UART pins and exposes `LED_out` for debug.

**Ports:**
- `CLK`, `RST`: System clock and active-low reset.
- `Rx_in`: UART serial input.
- `Tx_out`: UART serial output.
- `LED_out`: Debug output (MSB of result).

## Detailed Data Flow

```mermaid
graph TD
    %% External Input
    A[UART rx - Serial Input] --> B[receiver.v - UART Receiver]

    %% Data Flow through Core
    B -->|Rx_Byte + Rx_DV| C["Core.v<br/>(aggregator)"]

    %% Inside Core
    C --> E["Controller.v<br/>(FSM: IDLE/LOAD/EXE/SEND)"]
    C --> D["Datapath.v<br/>(Add Q4.3 16-bit + Clamp)"]
    C --> MEM["Input_Memory.v<br/>(Save A/B as 16-bit)"]

    %% Internal connections
    E -->|Load_MSB_a_en| MEM
    E -->|Load_LSB_a_en| MEM
    E -->|Load_MSB_b_en| MEM
    E -->|Load_LSB_b_en| MEM
    MEM -->|a_out, b_out| D
    E -->|En_out| D
    D -->|c_out + c_valid| E

    %% Output: Send MSB then LSB
    E -->|Tx_DV + MLSB_SEL| F["transmitter.v<br/>(UART Transmitter)"]
    D -->|c_out[15:8] or [7:0]| F
    F --> G[UART tx - Serial Output]

    %% Top-level
    H["Add_IP.v<br/>(Top-Level Wrapper)"] -->|Instantiates| B
    H -->|Instantiates| C
    H -->|Instantiates| F

    %% Debug
    D -.->|Debug| I["LED_out = c_out[15:8]"]

    %% Styling
    classDef uart fill:#50e3c2,stroke:#000,color:#000
    classDef mem fill:#4ecdc4,stroke:#000,color:#fff
    classDef dp fill:#f7dc6f,stroke:#000,color:#000
    classDef ctrl fill:#ff6b6b,stroke:#000,color:#fff
    classDef top fill:#9013fe,stroke:#fff,color:#fff
    classDef core fill:#b8e986,stroke:#000,color:#000

    class A,B,F,G uart
    class MEM mem
    class D dp
    class E ctrl
    class H top
    class C core
```