ht = wlanHTCowlanHTConfignfig; %creating high throughput (HT) configuration 
ht.NumTransmitAntennas = 2;
ht.NumSpaceTimeStreams = 2 ;
%ht.MCS = 8; %BPSK 1/2
ht.MCS = 15; %64QAM	5/6

ht.ChannelBandwidth = 'CBW20'; % 20 MHz

bits = [1;0;0;1];

idle_time = 1;

if idle_time == 1
    tx = wlanWaveformGenerator(bits,ht,'NumPackets',3);
else
    tx = wlanWaveformGenerator(bits,ht,'NumPackets',3,'IdleTime',30e-6);
end

% normalize to -1 1
tx2 = tx/max([max(abs(real(tx))) max(abs(imag(tx)))]); 

%% Saving as binary

if idle_time == 1
    fid = fopen('input_signal_idle0.dat','wb');
    fwrite(fid,single(tx2(:,1)),'float32');
    fclose(fid);

    fid = fopen('input_signal_idle1.dat','wb');
    fwrite(fid,single(tx2(:,2)),'float32');
    fclose(fid);
else
    fid = fopen('input_signal0.dat','wb');
    fwrite(fid,single(tx2(:,1)),'float32');
    fclose(fid);

    fid = fopen('input_signal1.dat','wb');
    fwrite(fid,single(tx2(:,2)),'float32');
    fclose(fid);
end