# HiCCE-s-Firmware
Here you can find all the files needed to reconstruc the firmware I developed as my thesis for getting my degree.  


# HiCCE-128 Firmware — 128-Channel Biopotential Acquisition on Zynq-7000

Full custom firmware stack for the **HiCCE-128**, an open-source 128-channel biopotential acquisition board developed by ICTP (Trieste, Italy) and Rockefeller University. This repository contains the complete Programmable Logic (PL) and Processing System (PS) firmware designed from scratch on a Zynq-7000 APSoC (ZedBoard), achieving continuous, real-time streaming of all 128 channels to a PC with zero data loss over 40-minute continuous sessions.

This was the first APSoC-based Final Degree Project (TFG) at Universidad Nacional de San Juan (UNSJ), Argentina  and has since been developed into a peer-reviewed paper accepted at CASE 2026.

Hackter.io Post: [Hackster.io project page](#) ·  Thesis report available on request

---

## Key Results

| Metric | Value |
|---|---|
| Channels | 128 (4× Intan RHA2132, 32 ch each) |
| ADC resolution | 18-bit (4× AD7982) |
| Per-channel sample rate | 15.4 kSPS |
| SPI interface clock | 16 MHz (worst-case timing margin per datasheet) |
| System clock | 100 MHz |
| Continuous streaming | Up to 40 min, zero data loss |
| EMI mitigation | Hand-built Faraday cage (Gaussian noise floor recovered, see report) |

---

## System Architecture

The system is organized in three layers:

1. **Programmable Logic (PL)** — Hand-written VHDL finite state machines controlling the SPI digital interface to the Intan RHA2132 amplifiers and AD7982 ADCs, with nanosecond-level timing margins. A buffering/reordering pipeline built from Xilinx AXI4-Stream FIFO and AXI4-Stream Switch IP (True Round-Robin arbitration) assembles the 128-channel array in LSL-compliant order before handoff to the PS via AXI4-Stream DMA.
2. **Processing System (PS)** — FreeRTOS on the ARM Cortex-A9, with an lwIP-based TCP/IP server streaming all 128 channels to a connected client. Three cooperating tasks: `Network_thread` (one-shot peripheral/network init), `Server_thread` (connection listener), `Data_sending` (DMA-fed streaming task).
3. **PC side** — Python + PySide6 GUI, repackaging the TCP stream as an LSL outlet compatible with MedusaBCI, NeuroPype, and any other Lab Streaming Layer–compatible neuroscience software.

```
Intan RHA2132 (×4) ──SPI──┐
AD7982 ADC (×4)    ──SPI──┴─► FSM digital interface ─► AXI4-Stream FIFO (×4)
                                                          │
                                                    AXI4-Stream Switch
                                                    (True Round-Robin)
                                                          │
                                                     AXI4-Stream DMA
                                                          │
                                              PS (FreeRTOS + lwIP, ARM Cortex-A9)
                                                          │
                                                    TCP/IP :7 stream
                                                          │
                                             PC: Python bridge ─► LSL outlet ─► MedusaBCI / NeuroPype
```

---

## Repository Structure

```
/PL
  HiCCE_Firmware.tcl     # Vivado project reconstruction script (write_project_tcl)
  HiCCE_Firmware.xsa     # Hardware handoff for Vitis (platform, IP, block design)
  /srcs                  # VHDL sources (FSMs, constraints)
/PS
  /Test_Hicce            # FreeRTOS + lwIP application source (C)
/docs
  # Architecture diagrams, timing diagrams, replication guide
README.md
```



## Hardware

- **Board:** HiCCE-128 (ICTP/Rockefeller University, open-source)
- **SoC platform:** ZedBoard (Zynq-7000 XC7Z020)
- **Analog front-end:** 4× Intan RHA2132 (32-channel amplifier/mux)
- **ADC:** 4× Analog Devices AD7982 (18-bit SAR)

## Acknowledgments

Hardware provided by the **International Centre for Theoretical Physics (ICTP)**, Trieste, Italy, which lent the HiCCE-128 board for the development of this completely new firmware stack.

## Author

**Juan Manuel Sañudo** — Bioengineer, Universidad Nacional de San Juan (UNSJ), Argentina.
Open to remote  work in FPGA/embedded firmware.


