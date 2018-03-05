./tx_mimo --args="addr0=192.168.25.2, addr1=192.168.25.3" \
	--rate=25e6 \
	--freq=2e9 \
	--gain=40 \
	--ant="TX/RX" \
	--nsamps=8000 \
	--in0="../data/wlan_ch0.bin" \
	--in1="../data/wlan_ch1.bin"
