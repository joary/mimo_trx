
# The setup

1. **PC1** (assumed to be TX)
  1. Conected to USRP `192.168.25.2` and `192.168.25.3`
1. **PC2** (assumed to be RX)
  1. Conected to USRP `192.168.10.3` and `192.168.25.4`

# Initial Network Configuration

This procedure is mandatory before running the system for the first time after boot:

On PC1 run:

```
sudo bash ~/mimo_trx/ut_setup/net_tx_setup.sh
```

On PC2 run:

```
sudo bash ~/mimo_trx/ut_setup/net_rx_setup.sh
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
| 2 Spatial Stream | `rx_2st_2GHz_ch0.dat`, `rx_2st_2GHz_ch1.dat` | `rx_2st_900MHz_ch0.dat`, `rx_2st_900MHz_ch1.dat` |
