
# The setup

1. **PC1** (assumed to be TX)
  1. Conected to USRP `192.168.25.2` and `192.168.25.3`
1. **PC2** (assumed to be RX)
  1. Conected to USRP `192.168.10.3` and `192.168.25.4`

# Initial Network Configuration

This procedure is mandatory before running the system for the first time after boot:

On PC1 run:

```
sudo bash ~/mimo_trx/ut_setup/net25_setup.sh
```

On PC2 run:

```
sudo bash ~/mimo_trx/ut_setup/net10_setup.sh
```

# Run TX and RX

go to the example setup:

```
cd ~/mimo_trx/ut_setup
```

Select one of preconfigured scripts

|    | 2GHz | 900MHz |
|:--:|:--:|:--:|
| 1 Spatial Stream | `tx_1st_2GHz.sh` / `rx_1st_2GHz.sh` | `tx_1st_900MHz.sh` / `rx_1st_900MHz.sh` |
| 2 Spatial Stream | `tx_2st_2GHz.sh` / `rx_2st_2GHz.sh` | `tx_2st_900MHz.sh` / `rx_2st_900MHz.sh` |

Run the scripts `tx_*` in one machine and `rx_*` script in the other, for example for the 2GHz and 1 Spatial stream configuration:

In PC1:
```
./tx_1st_2GHz.sh
```

In PC2:
```
./rx_1st_2GHz.sh
```

Each `rx_*` script will generate a pair of recorded signal 

|    | 2GHz | 900MHz |
|:--:|:--:|:--:|
| 1 Spatial Stream | `rx_1st_2GHz_ch0.dat`, `rx_1st_2GHz_ch1.dat` | `rx_1st_900MHz_ch0.dat`, `rx_1st_900MHz_ch1.dat` |
| 2 Spatial Streams | `rx_2st_2GHz_ch0.dat`, `rx_2st_2GHz_ch1.dat` | `rx_2st_900MHz_ch0.dat`, `rx_2st_900MHz_ch1.dat` |

# Decoding Data

A copy of matlab workspace used to generate the transmitted signals is hold in:
1. For 1 Spatial Stream: `~/mimo_trx/data/MCS9_QPSK_rate1-2_config.mat`
2. For 2 Spatial Streams: `~/mimo_trx/data/MCS1_QPSK_rate1-2_config.mat`

On the other hand, to read the received signals the following matlab code can be used.

```
ch0_file = rx_**_ch0.dat
ch1_file = rx_**_ch1.dat

% Load data
fid = fopen(ch0_file,'r'); 
rx0 = fread(fid,'float32'); 
fclose(fid);
fid = fopen(ch1_file,'r');
rx1 = fread(fid,'float32');
fclose(fid);
rx0c = rx0(1:2:end-1) + rx0(2:2:end)*1j;
rx1c = rx1(1:2:end-1) + rx1(2:2:end)*1j;
rx = [rx0c(1e4:end), rx1c(1e4:end)];
```

In addition, the script in `~/mimo_trx/matlab/decode_rx.m` can be used to decode the received signal and compare to the transmitted.
