#!/usr/bin/python

import sys
from pylab import *
import struct

if __name__ == '__main__':
    a = sys.argv;
    if(len(a) != 3):
        print('Usage')
        exit(-1);
    f_name1 = a[1];
    f_name2 = a[2];
    print("Generating", f_name1, f_name2)

    n_samples = 10240;
    freq1 = 512;
    freq2 = 2048;

    s1 = 0.5*exp(1j*arange(n_samples) * 2*pi * freq1 / n_samples);
    s2 = 0.5*exp(1j*arange(n_samples) * 2*pi * freq2 / n_samples);

    s_iq = []
    for i in s1:
        s_iq += [real(i), imag(i)];
    s_pack = struct.pack("<%df"%(len(s_iq)), *s_iq)
    f = open(f_name1, 'wb');
    f.write(s_pack)
    f.close();

    s_iq = []
    for i in s2:
        s_iq += [real(i), imag(i)];
    s_pack = struct.pack("<%df"%(len(s_iq)), *s_iq)
    f = open(f_name2, 'wb');
    f.write(s_pack)
    f.close();
