all: rx_mimo tx_mimo

rx_mimo:
	g++  -L /usr/lib  -I /usr/include -lboost_program_options -lboost_system -lboost_thread -luhd rx_mimo.cpp -o rx_mimo

tx_mimo:
	g++  -L /usr/lib  -I /usr/include -lboost_program_options -lboost_system -lboost_thread -luhd tx_mimo.cpp -o tx_mimo

clean:
	rm -rf rx_mimo tx_mimo
