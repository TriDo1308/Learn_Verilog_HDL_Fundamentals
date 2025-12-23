# Tic-Tac-Toe AI on FPGA with Minimax Algorithm

## Overview

This project implements a fully functional Tic-Tac-Toe game on FPGA using Verilog, featuring an **unbeatable AI opponent** based on the complete Minimax algorithm. The FPGA plays as 'O' (minimizing player) and always returns the theoretically optimal move. The human player ('X') interacts through a PC via UART (115200 baud, 8N1).  

Key features:
- Game controller implemented as a Finite State Machine (FSM).
- 18-bit flat board memory (2 bits per cell: 00=EMPTY, 01=X, 10=O).
- Combinational win/draw detection.
- Stack-based iterative Minimax engine (hardware-friendly, no recursion).
- Bidirectional UART protocol for move exchange and game status.
- LED debug output showing occupied cells.
- Companion C console program (`main.c`) for easy playtesting.

The design is fully synthesizable and has been successfully implemented and tested on FPGA.

## 📁 Project Structure

- `Controller.v`          : Main game FSM and UART protocol handler
- `Board_memory.v`        : 18-bit board storage with write/clear support
- `Core.v`                : Integration module for all sub-components
- `receiver.v`            : UART receiver (115200 baud)
- `Minimax.v`             : Full Minimax AI engine (iterative DFS with stack)
- `TicTacToe_IP.v`        : Top-level IP wrapper
- `Win_check.v`           : Win and draw detection logic
- `transmitter.v`         : UART transmitter (115200 baud)
- `main.c`                : PC-side console application for playing the game

## Module Descriptions

### 📤 `Controller.v`

Main Finite State Machine controlling the entire game flow and UART communication protocol. It has four states: IDLE, WAIT_MOVE (waiting for player 'X' move), FPGA_MOVE (triggering AI and placing 'O'), and CHECK (sending game result).

**Functionality:**
- Validates incoming player moves
- Updates board memory
- Triggers Minimax when it's AI's turn
- Sends acknowledgments, AI moves, and game status via UART

**Ports:**
- `CLK`, `RST`: System clock and active-low reset
- `Rx_Byte_in[7:0]`, `Rx_DV_in`: Received byte and data valid from UART receiver
- `Tx_Done_in`: Transmission complete flag from transmitter
- `board_flat[17:0]`: Current board state from memory
- `x_win`, `o_win`, `full`: Win/draw signals from Win_Check
- `ai_move[3:0]`, `ai_valid`: Best move and valid flag from Minimax
- `addr_mem[3:0]`, `data_in_mem[1:0]`, `we_mem`, `clear_board`: Control signals to Board_Memory
- `Tx_DV`, `Tx_Byte[7:0]`: Data valid and byte to transmitter
- `current_state_out[1:0]`: Debug output of current FSM state

### 📤 `Board_memory.v`

Synchronous register-based memory storing the 3x3 board as an 18-bit flat vector (2 bits per cell).

**Functionality:**
- Writes a single cell on clock edge when `we` is asserted
- Clears entire board when `clear` is high
- Resets to empty on hardware reset

**Ports:**
- `CLK`, `RST`: Clock and active-low reset
- `addr[3:0]`: Address of cell to write (0–8)
- `data_in[1:0]`: Data to write (01 for X, 10 for O)
- `we`: Write enable
- `clear`: Clear entire board
- `board_flat[17:0]`: Flat board output (read combinational)

### 📤 `Core.v`

Central integration module that instantiates and connects Controller, Board_Memory, Win_Check, and Minimax.

**Functionality:**
- Routes all data and control signals between submodules
- Generates 8-bit LED output showing occupied cells

**Ports:**
- `CLK`, `RST`: Clock and reset
- `Rx_Byte_in[7:0]`, `Rx_DV_in`: From UART receiver
- `Tx_Done_in`: From UART transmitter
- `Tx_DV_out`, `Tx_Byte_out[7:0]`: To UART transmitter
- `board_led[7:0]`: LED output (one bit per cell, high if occupied)

### 📤 `receiver.v`

UART receiver module parameterized for 115200 baud (CLKS_PER_BIT = 217 at 50 MHz clock).

**Functionality:**
- Samples serial input, synchronizes with double-flop
- Detects start bit, captures 8 data bits (LSB first), verifies stop bit
- Asserts `Rx_DV_out` for one cycle when byte is valid

**Ports:**
- `CLK`: System clock
- `Rx_in`: Serial input pin
- `Rx_DV_out`: Data valid pulse
- `Rx_Byte_out[7:0]`: Received byte

### 📤 `Minimax.v`

Core AI engine implementing complete Minimax using iterative depth-first search with an explicit stack (max depth 9).

**Functionality:**
- Scans possible 'O' moves in custom order (center first for faster convergence)
- Uses stack to store board state, is_max flag, best score, and try_pos (to resume search after backtracking)
- Terminal node scoring: +99-depth (X win), -99+depth (O win), 0 (draw)
- Pure combinatorial helper functions for cell access, win check, and empty position finding
- Outputs optimal move when computation complete

**Ports:**
- `CLK`, `RST`: Clock and reset
- `board_flat[17:0]`: Current board state
- `request`: Trigger from Controller (high during FPGA_MOVE state)
- `best_move[3:0]`: Optimal position for 'O' (0–8)
- `valid`: Pulse indicating computation complete

### 📤 `TicTacToe_IP.v`

Top-level wrapper module exposing the complete IP to external pins.

**Functionality:**
- Instantiates receiver, Core, and transmitter
- Connects internal wires to external ports

**Ports:**
- `CLK`, `RST`: Clock and active-low reset
- `Rx_in`: UART serial input
- `Tx_out`: UART serial output
- `LED[7:0]`: Board occupancy debug LEDs

### 📤 `Win_check.v`

Pure combinational logic for win and draw detection.

**Functionality:**
- Checks all 8 winning patterns for both X and O
- Sets `full` when no empty cells remain

**Ports:**
- `board_flat[17:0]`: Board input
- `x_win`, `o_win`: High if respective player has won
- `full`: High if board is full (draw possible)

### 📤 `transmitter.v`

UART transmitter module (115200 baud).

**Functionality:**
- Serializes byte with start bit, 8 data bits (LSB first), and stop bit
- Asserts `Tx_Done_out` when transmission complete

**Ports:**
- `CLK`: System clock
- `Tx_DV_in`: Data valid input (start transmission)
- `Tx_Byte_in[7:0]`: Byte to transmit
- `Tx_Active_out`: Transmission in progress (optional)
- `Tx_out`: Serial output pin
- `Tx_Done_out`: Transmission complete pulse

### 📤 `main.c`

PC-side console application written in C for playing against the FPGA via UART.

**Functionality:**
- Displays board and accepts player moves
- Implements full UART protocol including start, move, reset
- Handles multiple games

## 🔄 Detailed Data Flow

```mermaid
flowchart LR
    %% External
    subgraph External ["External Interface"]
        direction TB
        PC_TX[PC → UART Tx] --> RX[receiver.v<br/>UART Receiver]
        TX[transmitter.v<br/>UART Transmitter] --> PC_RX[UART Rx → PC]
    end

    %% Top Level
    subgraph Top ["TicTacToe_IP.v - Top Level"]
        direction TB
        RX --> CORE[Core.v<br/>Main Integrator]
        CORE --> TX
    end

    %% Core Internal
    subgraph Core ["Core.v - Internal Modules"]
        direction TB
        CTRL[Controller.v<br/>Game FSM]:::ctrl
        MEM[Board_Memory.v<br/>Board State]:::mem
        WIN[Win_Check.v<br/>Win/Draw Check]:::win
        AI[Minimax.v<br/>AI Engine]:::ai

        CTRL -->|addr, data, we, clear| MEM
        MEM -->|board_flat| CTRL
        MEM -->|board_flat| WIN
        MEM -->|board_flat| AI

        WIN -->|x_win, o_win, full| CTRL
        CTRL -->|request| AI
        AI -->|ai_move, ai_valid| CTRL

        CTRL -->|Tx_DV, Tx_Byte| TX
    end

    %% Debug
    MEM -.->|Occupancy| LED[LED Output<br/>Board Visualization]

    %% Styling
    classDef ctrl fill:#ff6b6b,stroke:#333,color:#fff
    classDef mem fill:#4ecdc4,stroke:#333,color:#fff
    classDef win fill:#f7dc6f,stroke:#333,color:#000
    classDef ai fill:#9013fe,stroke:#fff,color:#fff