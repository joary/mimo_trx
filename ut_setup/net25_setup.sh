
sudo sysctl -w net.core.rmem_max 50000000
sudo sysctl -w net.core.wmem_max 50000000
sudo ifconfig enp6s0:1 192.168.25.254/24 
