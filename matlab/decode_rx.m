clear all;
close all;

mode = '2st_2GHz';
loopback = false;

if loopback
    if strcmp(mode, '1st_2GHz') || strcmp(mode, '1st_900Hz')
        config_file = '../data/MCS1_QPSK_rate1-2_config.mat'; 
        ch0_file = '../data/MCS1_QPSK_rate1-2_ch0.bin';
        ch1_file = '../data/MCS1_QPSK_rate1-2_ch1.bin';
    elseif strcmp(mode, '2st_2GHz') || strcmp(mode, '2st_900Hz')
        config_file = '../data/MCS9_QPSK_rate1-2_config.mat'; 
        ch0_file = '../data/MCS9_QPSK_rate1-2_ch0.bin';
        ch1_file = '../data/MCS9_QPSK_rate1-2_ch1.bin';
    end
else
    if strcmp(mode, '1st_2GHz')
        config_file = '../data/MCS1_QPSK_rate1-2_config.mat';
        ch0_file = '../ut_setup/rx_1st_2GHz_ch0.dat';
        ch1_file = '../ut_setup/rx_1st_2GHz_ch1.dat';
    elseif strcmp(mode, '2st_2GHz')
        config_file = '../data/MCS9_QPSK_rate1-2_config.mat';
        ch0_file = '../ut_setup/rx_2st_2GHz_ch0.dat';
        ch1_file = '../ut_setup/rx_2st_2GHz_ch1.dat';
    elseif strcmp(mode, '1st_900MHz')
        config_file = '../data/MCS1_QPSK_rate1-2_config.mat';
        ch0_file = '../ut_setup/rx_1st_900MHz_ch0.dat';
        ch1_file = '../ut_setup/rx_1st_900MHz_ch1.dat';
    elseif strcmp(mode, '2st_900MHz')
        config_file = '../data/MCS9_QPSK_rate1-2_config.mat';
        ch0_file = '../ut_setup/rx_2st_900MHz_ch0.dat';
        ch1_file = '../ut_setup/rx_2st_900MHz_ch1.dat';
    end
end

load(config_file) % Load configurations from tx_data

ind = wlanFieldIndices(cfgHT);
fs = 20e6;
numPacketErrors = 0;
n = 0;

% Load data
fid = fopen(ch0_file,'r');
rx0 = fread(fid,'float32');
fclose(fid);
fid = fopen(ch1_file,'r');
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
    fprintf('Could not find coarse Packet Offset, Exiting\n')
    return
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
[rxPSDU, datasym] = wlanHTDataRecover(htdata,chanEst,nVarHT,cfgHT);

a = biterr(txPSDU,rxPSDU)/(cfgHT.PSDULength*8);
fprintf("N errrs %f\n", a)

plot(datasym(:), '.');

% Determine if any bits are in error, i.e. a packet error
%packetError = any(biterr(txPSDU,rxPSDU));
%numPacketErrors = numPacketErrors+packetError;
