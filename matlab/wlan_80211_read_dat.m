%% Read Files
%read the original signals

idle_time = 1;

if idle_time == 1

    fid = fopen('input_signal_idle0.dat','r');
    tx0_received = fread(fid,'float32');
    fclose(fid);

    fid = fopen('input_signal_idle1.dat','r');
    tx1_received = fread(fid,'float32');
    fclose(fid);

    fid = fopen('output_ch_idle0.dat','r');
    rx0_received = fread(fid,'float32');
    fclose(fid);

    fid = fopen('output_ch_idle1.dat','r');
    rx1_received = fread(fid,'float32');
    fclose(fid);

else 
    fid = fopen('input_signal0.dat','r');
    tx0_received = fread(fid,'float32');
    fclose(fid);

    fid = fopen('input_signal1.dat','r');
    tx1_received = fread(fid,'float32');
    fclose(fid);

    fid = fopen('output_ch1.dat','r');
    rx0_received = fread(fid,'float32');
    fclose(fid);

    fid = fopen('output_ch1.dat','r');
    rx1_received = fread(fid,'float32');
    fclose(fid);
    
end


%% 

rx0 = rx0_received(1:2:end-1) + rx0_received(2:2:end)*j;
rx1 = rx1_received(1:2:end-1) + rx1_received(2:2:end)*j;
tx0 = tx0_received(1:2:end-1) +  tx0_received(2:2:end)*j;
tx1 = tx1_received(1:2:end-1) +  tx1_received(2:2:end)*j;

clearvars rx0_received rx1_received %remove the received data from memory


