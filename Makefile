
LD=-lboost_program_options -lboost_system -lboost_thread -luhd -lm -lboost_math_c99 -lboost_math_c99f -lboost_math_c99l -lboost_math_tr1 -lboost_math_tr1f -lboost_math_tr1l

all: rx_mimo tx_mimo

rx_mimo: rx_mimo.cpp
	g++ -std=c++11 -I . -L /usr/lib  -I /usr/include rx_mimo.cpp  $(LD) -o rx_mimo

tx_mimo: tx_mimo.cpp
	g++ -std=c++11 -I . -L /usr/lib  -I /usr/include tx_mimo.cpp  $(LD) -o tx_mimo

clean:
	rm -rf rx_mimo tx_mimo
