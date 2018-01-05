Compile:
	run: make

Usage:
	* Transmit:
		1. Generate sample input file containing two sinusoids:
			./gen_tx_sig.py ./input_ch0.dat ./input_ch1.dat
		2. Run the trasnmitter application as shown in the run_tx.sh
			bash ./run_tx.sh

	* Receive:
		1. Run the receiver application as shown in the run_rx.sh
			bash ./run_rx.sh
		1. Show the content of saved files
			./plot_rx_files.py
