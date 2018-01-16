clear all;
close all;

cfgHT = wlanHTConfig;
cfgHT.ChannelBandwidth = 'CBW20'; % 20 MHz channel bandwidth
cfgHT.NumTransmitAntennas = 2;    % 2 transmit antennas
cfgHT.NumSpaceTimeStreams = 2;    % 2 space-time streams
cfgHT.PSDULength = 1000;          % PSDU length in bytes
cfgHT.MCS = 9;                   % 2 spatial streams, 64-QAM rate-5/6
cfgHT.ChannelCoding = 'BCC';      % BCC channel coding

ind = wlanFieldIndices(cfgHT);
fs = 20e6;
numPacketErrors = 0;
n = 0;

%wlan_80211_read_dat;

load tx_data

% Test selector
S = 2;
if S == 1% Test without air
	fid = fopen('wlan_ch0.dat','r');
	rx0 = fread(fid,'float32');
	fclose(fid);
	fid = fopen('wlan_ch1.dat','r');
	rx1 = fread(fid,'float32');
	fclose(fid);
	rx0c = rx0(1:2:end-1) + rx0(2:2:end)*1j;
	rx1c = rx1(1:2:end-1) + rx1(2:2:end)*1j;
elseif S == 2
	fid = fopen('../rx_wl_ch0.dat','r');
	rx0 = fread(fid,'float32');
	fclose(fid);
	fid = fopen('../rx_wl_ch1.dat','r');
	rx1 = fread(fid,'float32');
	fclose(fid);
	rx0c = rx0(1:2:end-1) + rx0(2:2:end)*1j;
	rx1c = rx1(1:2:end-1) + rx1(2:2:end)*1j;
end

%txPSDU = csvread('bits.csv');
rx = [rx0c, rx1c];
% rx = [rx0(1:4020*2), rx1(1:4020*2)];

% Packet detect and determine coarse packet offset
coarsePktOffset = wlanPacketDetect(rx,cfgHT.ChannelBandwidth)
if isempty(coarsePktOffset) % If empty no L-STF detected; packet error
    numPacketErrors = numPacketErrors+1;
    n = n+1;
end

% Extract L-STF and perform coarse frequency offset correction
lstf = rx(coarsePktOffset+(ind.LSTF(1):ind.LSTF(2)),:);
coarseFreqOff = wlanCoarseCFOEstimate(lstf,cfgHT.ChannelBandwidth)
rx = helperFrequencyOffset(rx,fs,-coarseFreqOff);

% Extract the non-HT fields and determine fine packet offset
nonhtfields = rx(coarsePktOffset+(ind.LSTF(1):ind.LSIG(2)),:);
finePktOffset = wlanSymbolTimingEstimate(nonhtfields,...
    cfgHT.ChannelBandwidth)

% Determine final packet offset
pktOffset = coarsePktOffset+finePktOffset

% Extract L-LTF and perform fine frequency offset correction
lltf = rx(pktOffset+(ind.LLTF(1):ind.LLTF(2)),:);
fineFreqOff = wlanFineCFOEstimate(lltf,cfgHT.ChannelBandwidth)
rx = helperFrequencyOffset(rx,fs,-fineFreqOff);

% Estimate noise power in HT fields
lltf = rx(pktOffset+(ind.LLTF(1):ind.LLTF(2)),:);
demodLLTF = wlanLLTFDemodulate(lltf,cfgHT.ChannelBandwidth);
nVarHT = helperNoiseEstimate(demodLLTF,cfgHT.ChannelBandwidth,...
    cfgHT.NumSpaceTimeStreams)

% Extract HT-LTF samples from the waveform, demodulate and perform
% channel estimation
htltf = rx(pktOffset+(ind.HTLTF(1):ind.HTLTF(2)),:);
htltfDemod = wlanHTLTFDemodulate(htltf,cfgHT);
chanEst = wlanHTLTFChannelEstimate(htltfDemod,cfgHT);

% Recover the transmitted PSDU in HT Data
% Extract HT Data samples from the waveform and recover the PSDU
htdata = rx(pktOffset+(ind.HTData(1):ind.HTData(2)),:);
rxPSDU = wlanHTDataRecover(htdata,chanEst,nVarHT,cfgHT);

a = biterr(txPSDU,rxPSDU)/(cfgHT.PSDULength*8);
fprintf("N errrs %f\n", a)

% Determine if any bits are in error, i.e. a packet error
%packetError = any(biterr(txPSDU,rxPSDU));
%numPacketErrors = numPacketErrors+packetError;
