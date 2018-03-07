clear all;
close all;

% Prerecorded Dual Spatial Stream
config_file = '../data/MCS1_QPSK_rate1-2_config.mat';
ch0_file = '../data/MCS1_QPSK_rate1-2_ch0.bin';
ch1_file = '../data/MCS1_QPSK_rate1-2_ch1.bin';

% Prerecorded Single Spatial Stream
%config_file = '../data/tx_data.mat';
%ch0_file = '../data/wlan_ch0.bin';
%ch1_file = '../data/wlan_ch1.bin';

% Recently Recorded
%ch0_file = '../rx_wl_ch0.bin';
%ch1_file = '../rx_wl_ch1.bin';

load(config_file) % Load configurations from tx_data

ind = wlanFieldIndices(cfgHT);
fs = 20e6;
numPacketErrors = 0;
n = 0;

% Test selector
fid = fopen(ch0_file,'r');
rx0 = fread(fid,'float32');
fclose(fid);
fid = fopen(ch0_file,'r');
rx1 = fread(fid,'float32');
fclose(fid);
rx0c = rx0(1:2:end-1) + rx0(2:2:end)*1j;
rx1c = rx1(1:2:end-1) + rx1(2:2:end)*1j;


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
