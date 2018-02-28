
#include <uhd/utils/thread_priority.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/thread.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/algorithm/string.hpp>
#include <iostream>
#include <complex>
#include <fstream>
#include <csignal>

namespace po = boost::program_options;

int UHD_SAFE_MAIN(int argc, char *argv[]){
    uhd::set_thread_priority_safe();

    //variables to be set by po
    std::string args, subdev, channel_list, ant, ch0_file, ch1_file;
    double seconds_in_future;
    size_t total_num_samps;
    double rate, freq, gain, bw = 0;

    //setup the program options
    po::options_description desc("Allowed options");
    desc.add_options()
        ("help", "help message")
        ("args", po::value<std::string>(&args)->default_value(""), "single uhd device address args")
        ("secs", po::value<double>(&seconds_in_future)->default_value(0.5), "number of seconds in the future to receive")
        ("nsamps", po::value<size_t>(&total_num_samps)->default_value(25000000), "total number of samples to receive")
        ("rate", po::value<double>(&rate)->default_value(100e6/16), "rate of incoming samples")
        ("freq", po::value<double>(&freq)->default_value(100e6), "center frequency of both receive channels")
        ("gain", po::value<double>(&gain)->default_value(0), "analog gain of both receive channels")
        ("bw", po::value<double>(&bw)->default_value(0), "analog bandwidth of both receive channels")
        ("ant", po::value<std::string>(&ant)->default_value("RX2"), "antenna port of both channels")
        ("subdev", po::value<std::string>(&subdev), "subdev spec (homogeneous across motherboards)")
        ("out0", po::value<std::string>(&ch0_file)->default_value("./output_ch0.dat"), "channel 0 output files")
        ("out1", po::value<std::string>(&ch1_file)->default_value("./output_ch1.dat"), "channel 1 output files")
    ;
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    //print the help message
    if (vm.count("help")){
        std::cout << boost::format("UHD RX Multi Samples %s") % desc << std::endl;
        std::cout <<
        "    This is a demonstration of how to receive aligned data from multiple channels.\n"
        "    This example can receive from multiple DSPs, multiple motherboards, or both.\n"
        "    The MIMO cable or PPS can be used to synchronize the configuration. See --sync\n"
        "\n"
        "    Specify --subdev to select multiple channels per motherboard.\n"
        "      Ex: --subdev=\"0:A 0:B\" to get 2 channels on a Basic RX.\n"
        "\n"
        "    Specify --args to select multiple motherboards in a configuration.\n"
        "      Ex: --args=\"addr0=192.168.10.2, addr1=192.168.10.3\"\n"
        << std::endl;
        return ~0;
    }

    bool verbose = vm.count("dilv") == 0;

    //create a usrp device
    std::cout << std::endl;
    std::cout << boost::format("Creating the usrp device with: %s...") % args << std::endl;
    uhd::usrp::multi_usrp::sptr usrp = uhd::usrp::multi_usrp::make(args);
    
    // Detect the channel configurations
    //   For 2x2 MIMO setup the USRP must have two channels
    std::vector<size_t> channel_nums;
    size_t n_chan = usrp->get_rx_num_channels();
    if (n_chan != 2){
            throw std::runtime_error("Invalid channel(s) specified, the USRP devices must have two channels");
            return ~0;
    }else{
            channel_nums.push_back(0);
            channel_nums.push_back(1);
    }
    std::cout << "N Channels: " << n_chan << "\n";
    
    // Setup clock source for each Mboard
    // The mother board 0 will use the internal clock source, while the mother board 1 will use MIMO clock
    size_t n_mboards = usrp->get_num_mboards();
    if( n_mboards != 2){
            throw std::runtime_error("Invalid mboard(s) specfied, the USRP devices must have two mboards");
            return ~0;
    }else{
            usrp->set_clock_source("internal", 0);
            usrp->set_clock_source("mimo", 1);
    }
    std::cout << "N Mboards: " << n_mboards << "\n";
    
    // Skip the setup of subdevice
    //   Ex: usrp->set_tx_subdev_spec(subdev);

    // Setup the sampling rate on TX
    usrp->set_rx_rate(rate);
    std::cout << "RX Rate: " << rate << "\n";
    
    // For each channel tune the Frequency, Gan and BW, and Antenna
    for(size_t ch = 0; ch < channel_nums.size(); ch++) {
        // Create tune-request and tune frequency
        uhd::tune_request_t tune_request(freq);
        // tune_request.args = uhd::device_addr_t("mode_n=integer");
        usrp->set_rx_freq(tune_request, channel_nums[ch]);
        usrp->set_rx_gain(gain, channel_nums[ch]);
        usrp->set_rx_bandwidth(bw, channel_nums[ch]);
        usrp->set_rx_antenna(ant, channel_nums[ch]);
        
        std::cout << "Ch"<<channel_nums[ch]<<" freq: "<<freq<<" gain: "<<gain<<" bw: "<<bw<<" antenna: "<<ant<<"\n";
    }
    boost::this_thread::sleep(boost::posix_time::seconds(1)); //allow for some setup time
    
    // Setup Time source on both motherboads
    usrp->set_time_now(uhd::time_spec_t(0.0), 0); // Time zero for MB0
    usrp->set_time_source("mimo", 1); // Time reference from MIMO for MB1
    boost::this_thread::sleep(boost::posix_time::milliseconds(100)); //allow for some setup time

    //create a receive streamer
    //linearly map channels (index0 = channel0, index1 = channel1, ...)
    uhd::stream_args_t stream_args("fc32", "sc8"); //complex floats
    stream_args.channels = channel_nums;
    uhd::rx_streamer::sptr rx_stream = usrp->get_rx_stream(stream_args);
    
    // Check MIMO and LO Locked on sensors
#if 0
    std::vector<std::string> sensor_names;
    const size_t tx_sensor_chan = channel_list.empty() ? 0 : boost::lexical_cast<size_t>(channel_list[0]);
    sensor_names = usrp->get_tx_sensor_names(tx_sensor_chan);
    if (std::find(sensor_names.begin(), sensor_names.end(), "lo_locked") != sensor_names.end()) {
        uhd::sensor_value_t lo_locked = usrp->get_tx_sensor("lo_locked", tx_sensor_chan);
        std::cout << boost::format("Checking TX: %s ...") % lo_locked.to_pp_string() << std::endl;
        UHD_ASSERT_THROW(lo_locked.to_bool());
    }
    const size_t mboard_sensor_idx = 0;
    sensor_names = usrp->get_mboard_sensor_names(mboard_sensor_idx);
    if (std::find(sensor_names.begin(), sensor_names.end(), "mimo_locked") != sensor_names.end()) {
        uhd::sensor_value_t mimo_locked = usrp->get_mboard_sensor("mimo_locked", mboard_sensor_idx);
        std::cout << boost::format("Checking TX: %s ...") % mimo_locked.to_pp_string() << std::endl;
        UHD_ASSERT_THROW(mimo_locked.to_bool());
    }
#endif

    //setup streaming
    std::cout << std::endl;
    std::cout << boost::format(
        "Begin streaming %u samples, %f seconds in the future..."
    ) % total_num_samps % seconds_in_future << std::endl;
    uhd::stream_cmd_t stream_cmd(uhd::stream_cmd_t::STREAM_MODE_NUM_SAMPS_AND_DONE);
    stream_cmd.num_samps = total_num_samps;
    stream_cmd.stream_now = false;
    stream_cmd.time_spec = uhd::time_spec_t(seconds_in_future);
    rx_stream->issue_stream_cmd(stream_cmd); //tells all channels to stream

    //meta-data will be filled in by recv()
    uhd::rx_metadata_t md;

    //allocate buffers to receive with samples (one buffer per channel)
    const size_t samps_per_buff = rx_stream->get_max_num_samps();
    std::vector<std::vector<std::complex<float> > > buffs(
        usrp->get_rx_num_channels(), std::vector<std::complex<float> >(samps_per_buff)
    );

    //create a vector of pointers to point to each of the channel buffers
    std::vector<std::complex<float> *> buff_ptrs;
    for (size_t i = 0; i < buffs.size(); i++) buff_ptrs.push_back(&buffs[i].front());
    
    std::vector<std::vector<std::complex<float> > > rx_buff(
        usrp->get_rx_num_channels(), std::vector<std::complex<float> >(total_num_samps)
    );
    uint64_t rx_idx = 0;

    //the first call to recv() will block this many seconds before receiving
    double timeout = seconds_in_future + 0.1; //timeout (delay before receive + padding)

    size_t num_acc_samps = 0; //number of accumulated samples
    while(num_acc_samps < total_num_samps){
        //receive a single packet
        size_t num_rx_samps = rx_stream->recv(
            buff_ptrs, samps_per_buff, md, timeout
        );
        
        for(size_t n =0; n< num_rx_samps; n++){
                rx_buff[0][rx_idx] = buffs[0][n];
                rx_buff[1][rx_idx] = buffs[1][n];
                rx_idx += 1;
                //std::cout << buffs[1][n] << "\n";
        }

        //use a small timeout for subsequent packets
        timeout = 0.1;
        //std::cout << num_acc_samps << " of " << total_num_samps << "\n";

        //handle the error code
        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_TIMEOUT) break;
        if (md.error_code != uhd::rx_metadata_t::ERROR_CODE_NONE){
            throw std::runtime_error(str(boost::format(
                "Receiver error %s"
            ) % md.strerror()));
        }

        num_acc_samps += num_rx_samps;
    }

    if (num_acc_samps < total_num_samps) std::cerr << "Receive timeout before all samples received..." << std::endl;

    std::ofstream out_ch0_file, out_ch1_file;
    out_ch0_file.open(ch0_file, std::ofstream::binary);
    out_ch0_file.write((const char*)&rx_buff[0].front(), total_num_samps*sizeof(std::complex<float>));
    out_ch0_file.close();
    
    out_ch1_file.open(ch1_file, std::ofstream::binary);
    out_ch1_file.write((const char*)&rx_buff[1].front(), total_num_samps*sizeof(std::complex<float>));
    out_ch1_file.close();

    //finished
    std::cout << std::endl << "Done!" << std::endl << std::endl;

    return EXIT_SUCCESS;
}
