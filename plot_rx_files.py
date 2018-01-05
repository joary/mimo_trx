#!/usr/bin/python
from pylab import *
import struct

if __name__ == '__main__':
    nsamps = int(25e4);
    ncomp = nsamps*2;
    nbytes = ncomp * 4;
    f = open("./ramdisk/output_ch0.dat", 'rb')
    B = f.read(nbytes);
    C = struct.unpack("f"*ncomp,B);
    S = array(C[0::2]) + 1j*array(C[1::2]);
    s0 = S;

    f = open("./ramdisk/output_ch1.dat", 'rb')
    B = f.read(nbytes);
    C = struct.unpack("f"*(ncomp),B);
    C = list(C)
    S = array(C[0::2]) + 1j*array(C[1::2]);
    s1 = S;

    plot(s0); plot(s1);
    show();
