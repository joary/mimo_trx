
#include <uhd/utils/thread_priority.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/thread.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/math/special_functions/round.hpp>
#include <iostream>
#include <fstream>
#include <complex>
#include <csignal>
#include "wavetable.hpp"

namespace po = boost::program_options;

static bool stop_signal_called = false;
void sig_int_handler(int){stop_signal_called = true;}

/* List of things to setup transmitter for USRP
*/

int UHD_SAFE_MAIN(int argc, char *argv[]){
        uhd::set_thread_priority_safe();
        std::signal(SIGINT, &sig_int_handler);

        //variables to be set by po
        std::string args, sync, subdev, channel_list, ant, ch0_file, ch1_file;
        double seconds_in_future;
        size_t total_num_samps;
        double rate, freq, gain, bw;

        /************************** Parse Command Line **************************/
        //setup the program options
        po::options_description desc("Allowed options");
        desc.add_options()
                ("help", "help message")
                ("args", po::value<std::string>(&args)->default_value(""), "single uhd device address args")
                ("ant", po::value<std::string>(&args)->default_value("TX/RX"), "antenna port to use on both mimo channels")
                ("secs", po::value<double>(&seconds_in_future)->default_value(1.5), "number of seconds in the future to transmit")
                ("nsamps", po::value<size_t>(&total_num_samps)->default_value(10000), "number of samples to read from file")
                ("rate", po::value<double>(&rate)->default_value(100e6/16), "rate of incoming samples")
                ("freq", po::value<double>(&freq)->default_value(100e6), "tx_center_frequency on both mimo channels")
                ("gain", po::value<double>(&gain)->default_value(0), "trasmit gain on both mimo channels")
                ("bw", po::value<double>(&gain)->default_value(0), "analog bandwidth on both mimo channels")
                ("subdev", po::value<std::string>(&subdev), "subdev spec (homogeneous across motherboards)")
                ("in0", po::value<std::string>(&ch0_file)->default_value("./input_ch0.dat"), "channel 0 input file")
                ("in1", po::value<std::string>(&ch1_file)->default_value("./input_ch1.dat"), "channel 1 input file")
        ;
        po::variables_map vm;
        po::store(po::parse_command_line(argc, argv, desc), vm);
        po::notify(vm);

        //print the help message
        if (vm.count("help")){
                std::cout << boost::format("UHD RX Multi Samples %s") % desc << std::endl;
                std::cout <<
                "    This is a demonstration of how to transmit aligned data to multiple channels.\n"
                "    This example can transmit to multiple DSPs, multiple motherboards, or both.\n"
                "\n"
                "    Specify --subdev to select multiple channels per motherboard.\n"
                "      Ex: --subdev=\"0:A 0:B\" to get 2 channels on a Basic RX.\n"
                "\n"
                "    Specify --args to select multiple motherboards in a configuration.\n"
                "      Ex: --args=\"addr0=192.168.10.2, addr1=192.168.10.3\"\n"
                << std::endl;
                return ~0;
        }

        // Create USRP device
        //  args - the device address arguments:
        //    Ex0: "addr=192.168.10.2" for single USRP
        //    Ex1: "addr0=192.168.10.2,addr1=192.168.10.3" for MIMO USRP setup
        uhd::usrp::multi_usrp::sptr usrp = uhd::usrp::multi_usrp::make(args);

        // Detect the channel configurations
        //   For 2x2 MIMO setup the USRP must have two channels
        std::vector<size_t> channel_nums;
        size_t n_chan = usrp->get_tx_num_channels();
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
        usrp->set_tx_rate(rate);
        std::cout << "TX Rate: " << rate << "\n";

        // For each channel tune the Frequency, Gan and BW, and Antenna
        for(size_t ch = 0; ch < channel_nums.size(); ch++) {
            // Create tune-request and tune frequency
            uhd::tune_request_t tune_request(freq);
            // tune_request.args = uhd::device_addr_t("mode_n=integer");
            usrp->set_tx_freq(tune_request, channel_nums[ch]);
            usrp->set_tx_gain(gain, channel_nums[ch]);
            usrp->set_tx_bandwidth(bw, channel_nums[ch]);
            usrp->set_tx_antenna("TX/RX", channel_nums[ch]);
            
            std::cout << "Ch"<<channel_nums[ch]<<" freq: "<<freq<<" gain: "<<gain<<" bw: "<<bw<<" antenna: "<<ant<<"\n";
        }
        boost::this_thread::sleep(boost::posix_time::seconds(1)); //allow for some setup time

        // Setup Time source on both motherboads
        usrp->set_time_now(uhd::time_spec_t(0.0), 0); // Time zero for MB0
        usrp->set_time_source("mimo", 1); // Time reference from MIMO for MB1
        boost::this_thread::sleep(boost::posix_time::milliseconds(100)); //allow for some setup time

        // Create TX Streamer
        //   Use complex float as computer format
        //   Use complex short 8bits as wire format
        uhd::stream_args_t stream_args("fc32", "sc8");
        stream_args.channels = channel_nums;
        uhd::tx_streamer::sptr tx_stream = usrp->get_tx_stream(stream_args);

        // Check MIMO and LO Locked on sensors
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

        // Create timestamp metadada from transmitter
        uhd::tx_metadata_t md;
        md.start_of_burst = true;
        md.end_of_burst   = false;
        md.has_time_spec  = true;
        md.time_spec = usrp->get_time_now() + uhd::time_spec_t(0.1);

        // Setup transmitter buffer
        size_t spb = tx_stream->get_max_num_samps();
        std::vector<std::vector<std::complex<float> > > buff(
                usrp->get_rx_num_channels(), std::vector<std::complex<float> >(spb)
        );
        std::vector<std::complex<float> *> buffs;
        for (size_t i = 0; i < buff.size(); i++) buffs.push_back(&buff[i].front());
        
        
        const wave_table_class wave_table("SINE", 0.5);
        double wave_freq_1 = 1e6;
        const size_t step1 = boost::math::iround(wave_freq_1/usrp->get_tx_rate() * wave_table_len);
        size_t index1 = 0;
        double wave_freq_2 = 100e3;
        const size_t step2 = boost::math::iround(wave_freq_2/usrp->get_tx_rate() * wave_table_len);
        size_t index2 = 0;
        std::cout << " step1 " << step1 << " step2 " << step2 << "\n";

        size_t n_samples_in_file  = total_num_samps;
        std::vector<std::vector<std::complex<float> > > input_samples(
                usrp->get_rx_num_channels(), std::vector<std::complex<float> >(n_samples_in_file)
        );
        std::ifstream in_ch0_file(ch0_file, std::ifstream::binary);
        std::ifstream in_ch1_file(ch1_file, std::ifstream::binary);
        in_ch0_file.read((char*)&input_samples[0].front(), n_samples_in_file*sizeof(std::complex<float>));
        in_ch1_file.read((char*)&input_samples[1].front(), n_samples_in_file*sizeof(std::complex<float>));
        in_ch0_file.close();
        in_ch1_file.close();
        uint64_t file_idx = 0;
        
        //send data until the signal handler gets called
        //or if we accumulate the number of samples specified (unless it's 0)
        uint64_t num_acc_samps = 0;
        while(true){
                if(stop_signal_called) break;

#if 1           
                for (size_t n = 0; n < spb; n++){
                        buff[0][n] = input_samples[0][file_idx];
                        buff[1][n] = input_samples[1][file_idx];
                        file_idx = (file_idx + 1) % n_samples_in_file;
                }
                //std::cout << "idx " << file_idx << "\n";
                tx_stream->send(buffs, spb, md);
                md.start_of_burst = false;
                md.has_time_spec = false;
#else
                for (size_t n = 0; n < spb; n++){
                        buff[0][n] = wave_table(index1 += step1);
                        buff[1][n] = wave_table(index2 += step2);
                }
                std::cout << "Sending " << spb << "\n";
                tx_stream->send(buffs, spb, md);
                md.start_of_burst = false;
                md.has_time_spec = false;
#endif

        }

        md.end_of_burst = true;
        tx_stream->send("", 0, md);

        return EXIT_SUCCESS;
}
