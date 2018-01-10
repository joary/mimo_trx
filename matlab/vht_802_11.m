
% Create a format configuration object for a 2-by-2 HT transmission
cfgHT = wlanHTConfig;
cfgHT.ChannelBandwidth = 'CBW20'; % 20 MHz channel bandwidth
cfgHT.NumTransmitAntennas = 2;    % 2 transmit antennas
cfgHT.NumSpaceTimeStreams = 2;    % 2 space-time streams
cfgHT.PSDULength = 1000;          % PSDU length in bytes
cfgHT.MCS = 15;                   % 2 spatial streams, 64-QAM rate-5/6
cfgHT.ChannelCoding = 'BCC';      % BCC channel coding

% Create and configure the channel
tgnChannel = wlanTGnChannel;
tgnChannel.DelayProfile = 'Model-B';
tgnChannel.NumTransmitAntennas = cfgHT.NumTransmitAntennas;
tgnChannel.NumReceiveAntennas = 2;
tgnChannel.TransmitReceiveDistance = 10; % Distance in meters for NLOS
tgnChannel.LargeScaleFadingEffect = 'None';

snr = 25:10:45;

maxNumPEs = 10; % The maximum number of packet errors at an SNR point
maxNumPackets = 100; % Maximum number of packets at an SNR point

% Get the baseband sampling rate
fs = 20e6; %wlanSampleRate(cfgHT);

% Get the number of occupied subcarriers in HT fields and FFT length
[htData,htPilots] = helperSubcarrierIndices(cfgHT,'HT');
Nst_ht = numel(htData)+numel(htPilots);
Nfft = helperFFTLength(cfgHT);      % FFT length

% Set the sampling rate of the channel
tgnChannel.SampleRate = fs;

% Indices for accessing each field within the time-domain packet
ind = wlanFieldIndices(cfgHT);

S = numel(snr);
packetErrorRate = zeros(S,1);
%parfor i = 1:S % Use 'parfor' to speed up the simulation
for i = 1:S % Use 'for' to debug the simulation
    % Set random substream index per iteration to ensure that each
    % iteration uses a repeatable set of random numbers
    stream = RandStream('combRecursive','Seed',0);
    stream.Substream = i;
    RandStream.setGlobalStream(stream);

    % Create an instance of the AWGN channel per SNR point simulated
    awgnChannel = comm.AWGNChannel;
    awgnChannel.NoiseMethod = 'Signal to noise ratio (SNR)';
    % Normalization
    awgnChannel.SignalPower = 1/tgnChannel.NumReceiveAntennas;
    % Account for energy in nulls
    awgnChannel.SNR = snr(i)-10*log10(Nfft/Nst_ht);

    % Loop to simulate multiple packets
    numPacketErrors = 0;
    n = 1; % Index of packet transmitted
    while numPacketErrors<=maxNumPEs && n<=maxNumPackets
        % Generate a packet waveform
        txPSDU = randi([0 1],cfgHT.PSDULength*8,1); % PSDULength in bytes
        tx = wlanWaveformGenerator(txPSDU,cfgHT);

        % Add trailing zeros to allow for channel filter delay
        tx = [tx; zeros(15,cfgHT.NumTransmitAntennas)]; %#ok<AGROW>

        % Pass the waveform through the TGn channel model
        reset(tgnChannel); % Reset channel for different realization
        rx = tgnChannel(tx);

        % Add noise
        rx = awgnChannel(rx);

        % Packet detect and determine coarse packet offset
        coarsePktOffset = wlanPacketDetect(rx,cfgHT.ChannelBandwidth);
        if isempty(coarsePktOffset) % If empty no L-STF detected; packet error
            numPacketErrors = numPacketErrors+1;
            n = n+1;
            continue; % Go to next loop iteration
        end

        % Extract L-STF and perform coarse frequency offset correction
        lstf = rx(coarsePktOffset+(ind.LSTF(1):ind.LSTF(2)),:);
        coarseFreqOff = wlanCoarseCFOEstimate(lstf,cfgHT.ChannelBandwidth);
        rx = helperFrequencyOffset(rx,fs,-coarseFreqOff);

        % Extract the non-HT fields and determine fine packet offset
        nonhtfields = rx(coarsePktOffset+(ind.LSTF(1):ind.LSIG(2)),:);
        finePktOffset = wlanSymbolTimingEstimate(nonhtfields,...
            cfgHT.ChannelBandwidth);

        % Determine final packet offset
        pktOffset = coarsePktOffset+finePktOffset;

        % If packet detected outwith the range of expected delays from the
        % channel modeling; packet error
        if pktOffset>15
            numPacketErrors = numPacketErrors+1;
            n = n+1;
            continue; % Go to next loop iteration
        end

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
        packetError = any(biterr(txPSDU,rxPSDU));
        numPacketErrors = numPacketErrors+packetError;
        n = n+1;
    end

    % Calculate packet error rate (PER) at SNR point
    packetErrorRate(i) = numPacketErrors/(n-1);
    disp(['SNR ' num2str(snr(i)) ' completed after ' ...
        num2str(n-1) ' packets']);
end

%%

figure;
semilogy(snr,packetErrorRate,'-ob');
grid on;
xlabel('SNR [dB]');
ylabel('PER');
title('802.11n 20MHz, MCS15, Direct Mapping, 2x2 Channel Model B-NLOS');