
LD=-lboost_program_options -lboost_system -lboost_thread -luhd -lm -lboost_math_c99 -lboost_math_c99f -lboost_math_c99l -lboost_math_tr1 -lboost_math_tr1f -lboost_math_tr1l

all: rx_mimo tx_mimo

rx_mimo: rx_mimo.cpp
	g++ -I . -L /usr/lib  -I /usr/include $(LD) rx_mimo.cpp -o rx_mimo

tx_mimo: tx_mimo.cpp
	g++ -I . -L /usr/lib  -I /usr/include $(LD) tx_mimo.cpp -o tx_mimo

clean:
	rm -rf rx_mimo tx_mimo
