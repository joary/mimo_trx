#!/usr/bin/python
from pylab import *
import struct

if __name__ == '__main__':
    nsamps = int(25e4);
    ncomp = nsamps*2;
    nbytes = ncomp * 4;
    f = open("./rx_wl_ch0.dat", 'rb')
    B = f.read(nbytes);
    C = struct.unpack("f"*ncomp,B);
    S = array(C[0::2]) + 1j*array(C[1::2]);
    s0 = S;

    f = open("./rx_wl_ch1.dat", 'rb')
    B = f.read(nbytes);
    C = struct.unpack("f"*(ncomp),B);
    C = list(C)
    S = array(C[0::2]) + 1j*array(C[1::2]);
    s1 = S;

    figure()
    l1, = plot(s0, label="Channel 0"); 
    l2, = plot(s1, label="Channel 1");
    legend(handles=[l1, l2]);
    title("Time Domain absolute of both channels")
    figure()
    psd(s0);
    title("Spectrum of channel 0")
    figure()
    psd(s1);
    title("Spectrum of channel 1")
    show();
