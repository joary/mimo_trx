./rx_mimo --args="addr0=192.168.10.2, addr1=192.168.10.3" \
	--secs=1.5 \
	--rate=25e6 \
	--freq=2e9 \
	--gain=10 \
	--bw=0 \
	--nsamps=250000 \
	--ant="RX2" \
	--out0="./rx_wl_ch0.dat" \
	--out1="./rx_wl_ch1.dat"
