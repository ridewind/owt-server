https://registrationcenter-download.intel.com/akdlm/irc_nas/17062/l_openvino_toolkit_p_2021.1.110.tgz

./initowt.sh --hostname live.zhjxy.kp.futurelab.tv --externalip 121.36.3.228 --network_interface eth0 --deps --cert
./initowt.sh --hostname live.dev.yuyou --externalip 10.17.10.104 --network_interface ens160 --deps
./initowt.sh --hostname live.pdsu.futurelab.tv --externalip 124.70.59.124 --network_interface eth0 --deps --cert

./initowt.sh --hostname live.hbc.futurelab.tv --externalip 122.9.45.89 --network_interface eth0 --cert
live.hbc.futurelab.tv

docker update --restart always frps oj-backend judge-server oj-postgres oj-redis nginx
 
121.36.3.228 
