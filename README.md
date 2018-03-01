# MIMO Infrastructure for 802.11

## Components

1. **UHD Interface:** C++ Programs to send/receive MIMO streams for USRP N2X0 conected with MIMO Cable.
2. **Matlab Code:** Matlab code to generate/decode 802.11 MIMO signals
3. **Data:** pre-recorded 802.11 MIMO signals

## UHD Interface

To compile codes run `make`

check `tx_mimo --help` and `rx_mimo --help` to check configuration options

A of how to use both programs is shown in `run_tx.sh` and `run_rx.sh`. 
ATTENTION: the parameters must be adapted for each scenario.

# Matlab Code

A sample matlab code to generate 802.11 signal is shown in `matlab/encode_tx.m`, the same for the decoder at `matlab/decode_tx.sh`

# Data

A sample pre-recorded signal is hold in `data/wlan_ch0.bin` and `data/wlan_ch1.bin` for both MIMO channels.

The matlab workspace of the simualtion is held in `data/tx_data.mat`.

# Setup at Univ Texas