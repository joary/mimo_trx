%% Create a format configuration object for a 2-by-2 HT transmission

readData = 1;

cfgHT = wlanHTConfig; %creating high throughput (HT) configuration 
cfgHT.NumTransmitAntennas = 2;
cfgHT.NumSpaceTimeStreams = 2 ;
cfgHT.MCS = 8; %BPSK 1/2
% cfgHT.MCS = 15; %64QAM 5/6
cfgHT.ChannelBandwidth = 'CBW20'; % 20 MHz
fs = 20e6; %wlanSampleRate(cfgHT);

%% create tx and rx
 if readData == 0
     snr = 45;
     
     %Create and configure the channel
    tgnChannel = wlanTGnChannel;
    tgnChannel.DelayProfile = 'Model-B';
    tgnChannel.NumTransmitAntennas = cfgHT.NumTransmitAntennas;
    tgnChannel.NumReceiveAntennas = 2;
    tgnChannel.TransmitReceiveDistance = 1; % Distance in meters for NLOS
    tgnChannel.LargeScaleFadingEffect = 'None';

    % Get the number of occupied subcarriers in HT fields and FFT length
    [htData,htPilots] = helperSubcarrierIndices(cfgHT,'HT');
    Nst_ht = numel(htData)+numel(htPilots);
    Nfft = helperFFTLength(cfgHT);      % FFT length

    % Set the sampling rate of the channel
    tgnChannel.SampleRate = fs;

    % Indices for accessing each field within the time-domain packet
    ind = wlanFieldIndices(cfgHT);

    % Set random substream index per iteration to ensure that each
    % iteration uses a repeatable set of random numbers
    stream = RandStream('combRecursive','Seed',0);
    stream.Substream = 1;
    RandStream.setGlobalStream(stream);

    % Create an instance of the AWGN channel per SNR point simulated
    awgnChannel = comm.AWGNChannel;
    awgnChannel.NoiseMethod = 'Signal to noise ratio (SNR)';
    % Normalization
    awgnChannel.SignalPower = 1/tgnChannel.NumReceiveAntennas;
    % Account for energy in nulls
    awgnChannel.SNR = snr-10*log10(Nfft/Nst_ht);

    % Loop to simulate multiple packets
    numPacketErrors = 0;
    
    % Add trailing zeros to allow for channel filter delay
    tx = [tx; zeros(15,cfgHT.NumTransmitAntennas)]; 

    % 
    txPSDU = randi([0 1],cfgHT.PSDULength*8,1); % PSDULength in bytes
    tx = wlanWaveformGenerator(txPSDU,cfgHT);
    % Pass the waveform through the TGn channel model
    rx = tgnChannel(tx);
    % Add noise
    rx = awgnChannel(rx);

 else
    %read data

    bits = csvread('bits.csv'); %load bits

    fid = fopen('input_signal0.dat','rb');
    tx0_read = fread(fid,'float32');
    fclose(fid);

    fid = fopen('input_signal0.dat','rb');
    tx1_read = fread(fid,'float32');
    fclose(fid);

    txPSDU = bits;

    tx = double([tx0_read tx1_read]);
    clearvars tx0_read tx1_read


    fid = fopen('output_ch1.dat','rb');
    rx0_read = fread(fid,'float32');
    fclose(fid);

    fid = fopen('output_ch1.dat','rb');
    rx1_read = fread(fid,'float32');
    fclose(fid);

    rx = double([rx0_read(1:50000) rx1_read(1:50000)]);
    clearvars rx0_read rx1_read
    
end
 
%% demodulate
 
% Packet detect and determine coarse packet offset
coarsePktOffset = wlanPacketDetect(rx,cfgHT.ChannelBandwidth);


% Extract L-STF and perform coarse frequency offset correction
lstf = rx(coarsePktOffset+(ind.LSTF(1):ind.LSTF(2)),:);
coarseFreqOff = wlanCoarseCFOEstimate(lstf,cfgHT.ChannelBandwidth);
rx = helperFrequencyOffset(rx,fs,-coarseFreqOff);

% Extract the non-HT fields and determine fine packet offset
nonhtfields = rx(coarsePktOffset+(ind.LSTF(1):ind.LSIG(2)),:);
finePktOffset = wlanSymbolTimingEstimate(nonhtfields,...
    cfgHT.ChannelBandwidth);

% Determine final packet offset
pktOffset = coarsePktOffset+finePktOffset


% Extract L-LTF and perform fine frequency offset correction
lltf = rx(pktOffset+(ind.LLTF(1):ind.LLTF(2)),:);
fineFreqOff = wlanFineCFOEstimate(lltf,cfgHT.ChannelBandwidth);
rx = helperFrequencyOffset(rx,fs,-fineFreqOff);

% Estimate noise power in HT fields
lltf = rx(pktOffset+(ind.LLTF(1):ind.LLTF(2)),:);
demodLLTF = wlanLLTFDemodulate(lltf,cfgHT.ChannelBandwidth);
nVarHT = helperNoiseEstimate(demodLLTF,cfgHT.ChannelBandwidth,...
    cfgHT.NumSpaceTimeStreams);

% Extract HT-LTF samples from the waveform, demodulate and perform
% channel estimation
htltf = rx(pktOffset+(ind.HTLTF(1):ind.HTLTF(2)),:);
htltfDemod = wlanHTLTFDemodulate(htltf,cfgHT);
chanEst = wlanHTLTFChannelEstimate(htltfDemod,cfgHT);

% Recover the transmitted PSDU in HT Data
% Extract HT Data samples from the waveform and recover the PSDU
htdata = rx(pktOffset+(ind.HTData(1):ind.HTData(2)),:);
rxPSDU = wlanHTDataRecover(htdata,chanEst,nVarHT,cfgHT);

% Determine if any bits are in error, i.e. a packet error


%% calculate ber
[bitError bitErrorRate] = biterr(txPSDU,rxPSDU)