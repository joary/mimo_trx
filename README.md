# MIMO Infrastructure for 802.11

## Components

1. **UHD Interface:** C++ Programs to send/receive MIMO streams for USRP N2X0 conected with MIMO Cable.
  - To Compile the C++ code run `make`
  - Checkout the configuration options with: `tx_mimo --help` and  `rx_mimo --help`
  - An example configuration of how to run these applications is shown in `ut_setup/`
2. **Matlab Code (matlab/):** Matlab code to generate/decode 802.11 MIMO signals
3. **Data (data/):** pre-recorded 802.11 MIMO signals
  - The files  `data/wlan_ch0.bin` and `data/wlan_ch1.bin` store both MIMO channels of an 802.11n signal
  - The file `data/tc_data.mat` store the matlab workspace of the `matlab/encode_tx.m` used to generate the signal.

# Setup at Texas (ut_setup/)

Software configuration for UT setup:

1. Compile the UHD interface as shown previously
1. Create virtual ethernet interfaces to communicate with USRP's.
2. Run TX/RX configured with:
	1. Sampling Frequency: 25Msps
	2. Center Carrier Frequency: 2GHz
	3. Transmit Gain: 30dB and Receive Gain: 36dB
	

## First Time Setup
### For transmitter PC:

```
make
cd ut_setup/
sudo bash ./net25_setup.sh
bash ./run_tx.sh
```

### For receiver PC:

```
make
cd ut_setup/
sudo bash ./net10_setup.sh
bash ./run_rx.sh
```

# UHD Interface

## tx_mimo
```
#> tx_mimo --help

UHD RX Multi Samples Allowed options:
  --help                       help message
  --args arg                   single uhd device address args
  --ant arg (=TX/RX)           antenna port to use on both mimo channels
  --secs arg (=1.5)            number of seconds in the future to transmit
  --nsamps arg (=10000)        number of samples to read from file
  --rate arg (=6250000)        rate of incoming samples
  --freq arg (=100000000)      tx_center_frequency on both mimo channels
  --gain arg (=0)              trasmit gain on both mimo channels
  --bw arg (=0)                analog bandwidth on both mimo channels
  --subdev arg                 subdev spec (homogeneous across motherboards)
  --in0 arg (=./input_ch0.dat) channel 0 input file
  --in1 arg (=./input_ch1.dat) channel 1 input file

    This is a demonstration of how to transmit aligned data to multiple channels.
    This example can transmit to multiple DSPs, multiple motherboards, or both.

    Specify --subdev to select multiple channels per motherboard.
      Ex: --subdev="0:A 0:B" to get 2 channels on a Basic RX.

    Specify --args to select multiple motherboards in a configuration.
      Ex: --args="addr0=192.168.10.2, addr1=192.168.10.3"
```

## rx_mimo
```
#> rx_mimo --help

UHD RX Multi Samples Allowed options:
  --help                         help message
  --args arg                     single uhd device address args
  --secs arg (=0.5)              number of seconds in the future to receive
  --nsamps arg (=25000000)       total number of samples to receive
  --rate arg (=6250000)          rate of incoming samples
  --freq arg (=100000000)        center frequency of both receive channels
  --gain arg (=0)                analog gain of both receive channels
  --bw arg (=0)                  analog bandwidth of both receive channels
  --ant arg (=RX2)               antenna port of both channels
  --subdev arg                   subdev spec (homogeneous across motherboards)
  --out0 arg (=./output_ch0.dat) channel 0 output files
  --out1 arg (=./output_ch1.dat) channel 1 output files

    This is a demonstration of how to receive aligned data from multiple channels.
    This example can receive from multiple DSPs, multiple motherboards, or both.
    The MIMO cable or PPS can be used to synchronize the configuration. See --sync

    Specify --subdev to select multiple channels per motherboard.
      Ex: --subdev="0:A 0:B" to get 2 channels on a Basic RX.

    Specify --args to select multiple motherboards in a configuration.
      Ex: --args="addr0=192.168.10.2, addr1=192.168.10.3"
```
