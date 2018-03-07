./rx_mimo --args="addr0=192.168.10.4, addr1=192.168.10.3" \
	--secs=1.5 \
	--rate=25e6 \
	--freq=900e6 \
	--gain=23 \
	--bw=0 \
	--nsamps=250000 \
	--ant="TX/RX" \
	--out0="./rx_1st_900MHz_ch0.dat" \
	--out1="./rx_1st_900MHz_ch1.dat"
