# AXI-Lite Slave Design (Verilog/SystemVerilog)

A production-quality **AXI-Lite Slave peripheral** implemented in **SystemVerilog**, designed as part of my learning and hands-on practice in SoC, RTL design, and FPGA development.  
This repository demonstrates my capability in **AXI protocol implementation**, **RTL coding**, **state machines**, **memory-mapped interfaces**, and **verification with testbenches**.

---

## 🚀 Features

### ✔ Fully Functional AXI-Lite Slave
- Supports **32-bit AXI-Lite** interface  
- Implements all 5 AXI-Lite channels:
  - AW (Write Address)
  - W (Write Data)
  - B (Write Response)
  - AR (Read Address)
  - R (Read Data)
- Handles **independent AW/W ordering** (AXI-Lite compliant)

### ✔ Byte-level Write Support (WSTRB)
- Supports partial writes using **WSTRB**  
- Implements READ-MODIFY-WRITE on internal memory  
- Correct per-byte updates for 32-bit bus

### ✔ Internal Memory
- Synchronous memory with configurable **DEPTH**  
- Word-addressed using decoded AXI byte addresses

### ✔ Finite State Machine (FSM)
Clean, well-structured 6-state controller:
IDLE,
WRITE_CHANNEL,
WRESP_CHANNEL,
RADDR_CHANNEL,
RDATA_CHANNEL

Implements AXI-Lite handshake rules exactly as specified by ARM.

### ✔ Robust Error Handling
- `OKAY` for valid accesses  
- `DECERR` for out-of-range addresses  
- Easy to extend for SLVERR conditions

---

## 🧠 Skills Demonstrated

This project showcases the following engineering skills:

### ➤ RTL Design
- SystemVerilog RTL coding  
- Sequential + combinational logic separation  
- Non-blocking vs blocking assignment discipline  
- Word/byte address decoding  
- AXI-Lite protocol knowledge  

### ➤ Digital Design Concepts
- FSM design and implementation  
- Memory subsystem design  
- Byte-lane update logic  
- RMW (Read-Modify-Write) operations  
- Latch-free combinational logic  
- Synthesizable constructs for FPGA

### ➤ Verification
Includes self-checking testbench:
- AXI-Lite write transactions  
- AXI-Lite read transactions  
- Partial writes with multiple WSTRB patterns  
- Read-after-write verification  
- Works on:
  - **Vivado XSIM**
  - **ModelSim**
  - **Eda PlayGround**


---



