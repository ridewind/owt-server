################################
# OWT WebRTC server
#
# Base image Ubuntu 18.04


FROM ubuntu:18.04 AS owt-build
WORKDIR /home

# COMMON BUILD TOOLS
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -q --no-install-recommends build-essential autoconf make git wget pciutils cpio libtool lsb-release ca-certificates pkg-config bison flex libcurl4-gnutls-dev zlib1g-dev nasm yasm m4 autoconf libtool automake cmake libfreetype6-dev libgstreamer-plugins-base1.0-dev

RUN echo 'check_certificate = off' > $HOME/.wgetrc

# Build OWT specific modules
ARG OWTSERVER_REPO=https://github.com/ridewind/owt-server.git
ARG SERVER_PATH=/home/owt-server
ARG OWT_SDK_REPO=https://github.com/open-webrtc-toolkit/owt-client-javascript.git
ARG OWT_BRANCH="master"
ARG OWT_HEAD
#ENV LD_LIBRARY_PATH=/opt/intel/dldt/inference-engine/external/tbb/lib:/opt/intel/dldt/inference-engine/lib/intel64/

RUN git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name" && \
    git clone --depth=1 -b ${OWT_BRANCH} ${OWTSERVER_REPO} && \
    cd /home/owt-server
    
RUN ./scripts/installDepsUnattendedViaArg.sh install_apt_deps
RUN ./scripts/installDepsUnattendedViaArg.sh install_node
RUN ./scripts/installDepsUnattendedViaArg.sh install_mediadeps_nonfree
RUN ./scripts/installDepsUnattendedViaArg.sh install_node_tools
RUN ./scripts/installDepsUnattendedViaArg.sh install_zlib
RUN ./scripts/installDepsUnattendedViaArg.sh install_libnice014
RUN ./scripts/installDepsUnattendedViaArg.sh install_openssl
RUN ./scripts/installDepsUnattendedViaArg.sh install_openh264
RUN ./scripts/installDepsUnattendedViaArg.sh install_libre
RUN ./scripts/installDepsUnattendedViaArg.sh install_libexpat
RUN ./scripts/installDepsUnattendedViaArg.sh install_usrsctp
RUN ./scripts/installDepsUnattendedViaArg.sh install_libsrtp2
RUN ./scripts/installDepsUnattendedViaArg.sh install_quic
RUN ./scripts/installDepsUnattendedViaArg.sh install_licode
RUN ./scripts/installDepsUnattendedViaArg.sh install_svt_hevc
RUN ./scripts/installDepsUnattendedViaArg.sh install_json_hpp
RUN ./scripts/installDepsUnattendedViaArg.sh install_webrtc


    # Get js client sdk for owt
RUN cd /home && git clone --depth=1 ${OWT_SDK_REPO} && \
    cd owt-client-javascript/scripts && npm install -g grunt-cli node-gyp@6.1.0 && npm install && grunt
 
    #Build and pack owt
RUN cd ${SERVER_PATH} && ./scripts/build.js -t mcu -r -c && \
    ./scripts/pack.js -t all --install-module --no-pseudo -a ${OWT_BRANCH} -wf -f -p /home/owt-client-javascript/dist/samples/conference
