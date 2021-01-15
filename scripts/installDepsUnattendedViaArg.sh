#!/bin/bash
SCRIPT=`pwd`/$0
FILENAME=`basename $SCRIPT`
PATHNAME=`dirname $SCRIPT`
ROOT=$PATHNAME/..
BUILD_DIR=$ROOT/build
CURRENT_DIR=`pwd`

LIB_DIR=$BUILD_DIR/libdeps
PREFIX_DIR=$LIB_DIR/build/
DISABLE_NONFREE=true
CLEANUP=false
NIGHTLY=false
NO_INTERNAL=false
INCR_INSTALL=false
SUDO=""
DISABLE_NONFREE=false

if [[ $EUID -ne 0 ]]; then
  SUDO="sudo -E"
fi

cd $PATHNAME
mkdir -p $PREFIX_DIR

. installCommonDeps.sh
. installUbuntuDeps.sh

parse_arguments(){
  while [ "$1" != "" ]; do
    case $1 in
      "install_apt_deps")
        install_apt_deps
        ;;
      "install_node")
        install_node
        ;;
      "install_mediadeps_nonfree")
        install_mediadeps_nonfree
        ;;
      "install_node_tools")
        install_node_tools
        ;;
      "install_zlib")
        install_zlib
        ;;
      "install_libnice014")
        install_libnice014
        ;;
      "install_openssl")
        install_openssl
        ;;
      "install_openh264")
        install_openh264
        ;;
      "install_libre")
        install_libre
        ;;
      "install_libexpat")
        install_libexpat
        ;;
      "install_usrsctp")
        install_usrsctp
        ;;
      "install_libsrtp2")
        install_libsrtp2
        ;;
      "install_quic")
        install_quic_unattended
        ;;
      "install_licode")
        install_licode
        ;;
      "install_svt_hevc")
        install_svt_hevc
        ;;
      "install_json_hpp")
        install_json_hpp
        ;;
      "install_webrtc")
        install_webrtc
        ;;
    esac
    shift
  done
}

parse_arguments $*
