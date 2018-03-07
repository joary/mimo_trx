#!/bin/bash

../tx_mimo --args="addr0=192.168.25.2, addr1=192.168.25.3" \
	--rate=25e6 \
	--freq=2e9 \
	--gain=30 \
	--ant="TX/RX" \
	--nsamps=7040 \
	--in0="../data/MCS9_QPSK_rate1-2_ch0.bin" \
	--in1="../data/MCS9_QPSK_rate1-2_ch1.bin"
