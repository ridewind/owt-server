#!/bin/bash

# change workdir
cd /home/owt
this=$(pwd)

mongourl=localhost/owtdb
LOG=/dev/null

service mongodb start &
service rabbitmq-server start &

while ! mongo --quiet --eval "db.adminCommand('listDatabases')" >>$LOG 2>&1
do
    echo mongo is not ready. Waiting
    sleep 1
done

while ! rabbitmqctl -q status >> $LOG 2>&1
do
    echo RabbitMQ is not ready. Waiting...
    sleep 1
done

INSTALL_DEPS=false
INSTALL_CERT=false

# format the parameters
set -- $(getopt -u -l rabbit:,mongo:,hostname:,externalip:,network_interface::,cert,deps -- -- "$@")
# get the parameters
while [ -n "$1" ]
do
    case "$1" in
        --rabbit ) rabbitmqip=$2; shift; shift ;;
        --mongo ) mongourl=$2; shift; shift ;;
        --hostname ) hostname=$2; shift; shift ;;
        --externalip ) externalip=$2; shift; shift ;;
        --network_interface ) networkinterface=$2; shift; shift ;;
        --cert ) INSTALL_CERT=true; shift ;;
        --deps ) INSTALL_DEPS=true; shift ;;
        * ) break;;
    esac
done

alltoml=$(find . -maxdepth 2 -name "*.toml")
echo ${mongourl}
echo ${rabbitmqip}
for toml in $alltoml; do
  if [ ! -z "${mongourl}" ];then
    sed -i "/^dataBaseURL = /c \dataBaseURL = \"${mongourl}\"" $toml  
  fi

  if [ ! -z "${rabbitmqip}" ];then
    if [[ $toml == *"management_console"* ]]; then
     echo "Do not modify management_console"
    else
      sed -i "/^host = /c \host = \"${rabbitmqip}\"" $toml
    fi
 
  fi
done

if [ ! -z "${hostname}" ];then
    echo ${hostname}
    sed -i "/^hostname = /c \hostname = \"${hostname}\"" portal/portal.toml  
fi

if [ ! -z "${externalip}" ] && [ ! -z "{network_interface}" ];then
    echo ${externalip}
    sed -i "/^network_interfaces =/c \network_interfaces = [{name = \"${networkinterface}\", replaced_ip_address = \"${externalip}\"}]" webrtc_agent/agent.toml
    sed -i "/^ip_address = /c \ip_address =  \"${externalip}\"" portal/portal.toml  
fi

if ${INSTALL_CERT}; then
  cp -f ${this}/certificate.pfx ${this}/management_api/cert/certificate.pfx
  cp -f ${this}/certificate.pfx ${this}/portal/cert/certificate.pfx
  cp -f ${this}/certificate.pfx ${this}/webrtc_agent/cert/certificate.pfx
  cp -f ${this}/certificate.pfx ${this}/management_console/cert/certificate.pfx

  chmod +x ${this}/management_api/initcertauto.js
  chmod +x ${this}/portal/initcertauto.js
  chmod +x ${this}/webrtc_agent/initcertauto.js
  chmod +x ${this}/management_console/initcertauto.js

  ${this}/management_api/initcertauto.js
  ${this}/portal/initcertauto.js
  ${this}/webrtc_agent/initcertauto.js
  ${this}/management_console/initcertauto.js
fi

if ${INSTALL_DEPS}; then
  ${this}/video_agent/install_openh264.sh

  ${this}/video_agent/compile_svtHevcEncoder.sh 
  cp -f ${this}/svt_hevc_encoder/install/lib/libSvtHevcEnc.so.1  ${this}/video_agent/lib/
  chmod +x ${this}/video_agent/lib/*

  cp -rf ${this}/video_agent/lib/* ${this}/audio_agent/lib/
  cp -rf ${this}/video_agent/lib/* ${this}/recording_agent/lib/
  cp -rf ${this}/video_agent/lib/* ${this}/streaming_agent/lib/

  ${this}/audio_agent/compile_ffmpeg_with_libfdkaac.sh
  cp -rf ${this}/ffmpeg_libfdkaac_lib/* ${this}/audio_agent/lib/
fi

mkdir -p /recordings

./management_api/init.sh --dburl=${mongourl}

./bin/start-all.sh
