cfgHT = wlanHTConfig;
cfgHT.ChannelBandwidth = 'CBW20'; % 20 MHz channel bandwidth
cfgHT.NumTransmitAntennas = 2;    % 2 transmit antennas
cfgHT.NumSpaceTimeStreams = 2;    % 2 space-time streams
cfgHT.PSDULength = 1000;          % PSDU length in bytes
cfgHT.MCS = 15;                   % 2 spatial streams, 64-QAM rate-5/6
cfgHT.ChannelCoding = 'BCC';      % BCC channel coding

txPSDU = randi([0 1],cfgHT.PSDULength*8,1); % PSDULength in bytes
tx = wlanWaveformGenerator(txPSDU,cfgHT);
txn = 0.8*tx./max([max(abs(real(tx))) max(abs(imag(tx)))]); 

tx_data_ch0 = zeros(2*length(txn), 1);
tx_data_ch1 = zeros(2*length(txn), 1);

tx_data_ch0(1:2:end) = real(txn(:,1));
tx_data_ch0(2:2:end) = imag(txn(:,1));
tx_data_ch1(1:2:end) = real(txn(:,2));
tx_data_ch1(2:2:end) = imag(txn(:,2));

if true
save('tx_data')
fid = fopen('wlan_ch0.dat','wb');
fwrite(fid,single(tx_data_ch0),'float32');
fclose(fid);

fid = fopen('wlan_ch1.dat','wb');
fwrite(fid,single(tx_data_ch1),'float32');
fclose(fid);
end
