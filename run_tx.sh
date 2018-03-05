./tx_mimo --args="addr0=192.168.25.2, addr1=192.168.25.3" \
	--rate=10e6 \
	--freq=2.4e9 \
	--gain=20 \
	--ant="TX/RX" \
	--nsamps=14080 \
	--in0="./data/wlan_ch0.bin" \
	--in1="./data/wlan_ch1.bin"
