ht = wlanHTConfig; %creating high throughput (HT) configuration 
ht.NumTransmitAntennas = 2;
ht.NumSpaceTimeStreams = 2 ;
%ht.MCS = 8; %BPSK 1/2
ht.MCS = 15; %64QAM	5/6

ht.ChannelBandwidth = 'CBW20'; % 20 MHz

bits = [1;0;0;1];
tx = wlanWaveformGenerator(bits,ht,'NumPackets',100);

% normalize to -1 1
tx2 = tx/max([max(real(tx)) max(imag(tx))]); 
%%
%Saving as binary
fid = fopen('signal0.dat','wb');
fwrite(fid,single(tx2(:,1)),'float32');
fclose(fid);

fid = fopen('signal1.dat','wb');
fwrite(fid,single(tx2(:,2)),'float32');
fclose(fid);
