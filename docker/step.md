1. install tools

   ```shell	
   apt-get update && apt-get install -y -q --no-install-recommends ca-certificates wget xz-utils rabbitmq-server mongodb libboost-system-dev libboost-thread-dev liblog4cxx-dev libglib2.0-0 libfreetype6-dev curl cmake yasm libnss3
   ```

   

2. install node

   ```shell
    export NODE_VER=v10.21.0 && \
    export NODE_REPO=https://nodejs.org/dist/${NODE_VER}/node-${NODE_VER}-linux-x64.tar.xz && \
    wget ${NODE_REPO} && \
    tar xf node-${NODE_VER}-linux-x64.tar.xz && \
    cp node-*/* /usr/local -rf && rm -rf node-*
   ```

3. set env

   ```shell
   vim /etc/environment
   
   LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib/x86_64-linux-gnu
   
   source /etc/environment
   ```

   

4. copy owt files

   ### Install Server https://software.intel.com/content/www/us/en/develop/articles/intel-collaboration-suite-for-webrtc.html

5. Configure the MCU server machine

   1. Add or update the following lines in /etc/security/limits.conf, in order to set the maximum numbers of open files, running processes and maximum stack size to a large enough number:

      ```bash
       * hard nproc unlimited
       * soft nproc unlimited
       * hard nofile 163840
       * soft nofile 163840
       root hard nofile 163840
       root soft nofile 163840
       * hard stack 1024
       * soft stack 1024
      ```

      If you only want to target these settings to specific user or group rather than all with "*", please follow the configuration rules of the /etc/security/limits.conf file.

   2. Make sure `pam_limits.so` appears in /etc/pam.d/login as following:

      ```bash
      session required pam_limits.so
      ```

      So that the updated limits.conf takes effect after your next login.

   3. If you run MCU on CentOS, add or update the following two lines in /etc/security/limits.d/xx-nproc.conf as well:

      ```bash
      * soft nproc unlimited
       * hard nproc unlimited
      ```

   4. Add or update the following lines in /etc/sysctl.conf:

      ```bash
      fs.file-max=200000
       net.core.rmem_max=16777216
       net.core.wmem_max=16777216
       net.core.rmem_default=16777216
       net.core.wmem_default=16777216
       net.ipv4.udp_mem=4096 87380 16777216
       net.ipv4.tcp_rmem=4096 87380 16777216
       net.ipv4.tcp_wmem=4096 65536 16777216
       net.ipv4.tcp_mem=8388608 8388608 16777216
      ```

   5. Now run command /sbin/sysctl -p to activate the new configuration, or just restart your MCU machine.

   6. You can run command "ulimit -a" to make sure the new setting in limits.conf is correct as you set.

6. Deploy Cisco OpenH264* Library

   ```shell
    ./video_agent/install_openh264.sh
   ```

   

7. Compile and deploy ffmpeg with libfdk_aac

   ```shell
    ./audio_agent/compile_ffmpeg_with_libfdkaac.sh 
    cp -r ./ffmpeg_libfdkaac_lib/* ./audio_agent/lib/
   ```

   

8. Deploy SVT-HEVC Encoder Library ***存疑 从docker构建出来的owt本身应该是安装了svt-hevc的 

   ```shell
   ./video_agent/compile_svtHevcEncoder.sh 
   cp ./svt_hevc_encoder/install/lib/libSvtHevcEnc.so.1  ./video_agent/lib/
   chmod +x ./video_agent/lib/*
   ```

   

9. config certificate
   management_api/management_api.toml
   portal/portal.toml
   webrtc_agent/agent.toml
   management_console/management_console.toml

   ```shell
   ./management_api/initcert.js
   ./portal/initcert.js
   ./webrtc_agent/initcert.js
   ./management_console/initcert.js
   ```

10. Configuration Items for Public Access

    | Configuration Item                 | Location                           | Usage                                                        |
    | ---------------------------------- | ---------------------------------- | ------------------------------------------------------------ |
    | webrtc.network_interfaces          | webrtc_agent/agent.toml            | The network interfaces of webrtc-agent that clients in public network can connect to |
    | webrtc.minport                     | webrtc_agent/agent.toml            | The webrtc port range lowerbound for clients to connect through UDP |
    | webrtc.maxport                     | webrtc_agent/agent.toml            | The webrtc port range upperbound for clients to connect through UDP |
    | management-api.port                | management_api/management_api.toml | The port of management-api should be accessible in public network through TCP |
    | portal.hostname, portal.ip_address | portal/portal.toml                 | The hostname and IP address of portal for public access; hostname first if it is not empty. |
    | portal.port                        | portal/portal.toml                 | The port of portal for public access through TCP             |

    

11. recording_agent.toml
     ```toml
     path="/recordings"
     ```
    ```shell
    docker run \
    --restart=always \
    --name nginx \
    -d -p 18089:18089 \
    -v /home/nginx/fullchain.cer:/home/nginx/fullchain.cer:ro \
    -v /home/nginx/privatekey.key:/home/nginx/privatekey.key:ro \
    -v /home/nginx/log:/var/log/nginx \
    -v /home/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
    -v /home/nginx/conf.d:/etc/nginx/conf.d:ro \
    -v /recordings:/recordings \
    nginx
    ```

13. nginx.conf

    ```nginx
    user  root;  
    worker_processes  1;  
    error_log  /var/log/nginx/error.log warn;  
    pid        /var/run/nginx.pid;  
    
    events {  
        worker_connections  1024;  
    }  
    
    http {  
        include       /etc/nginx/mime.types;  
        default_type  application/octet-stream;  
    
        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '  
                          '$status $body_bytes_sent "$http_referer" '  
                          '"$http_user_agent" "$http_x_forwarded_for"';  
        access_log  /var/log/nginx/access.log  main;  
    
        sendfile        on;  
        #tcp_nopush     on;  
    
        keepalive_timeout  65;  
        autoindex  on;  
        #gzip  on;  
        include /etc/nginx/conf.d/*.conf;  
        client_max_body_size 100M;  
        client_header_buffer_size    128k;  
        large_client_header_buffers  4  128k;  
    } 
    ```

    

14. conf.d/defaut.conf
    ```nginx
    server {
        listen       18089 ssl;
        server_name  live.pdsu.futurelab.tv;
    
        ssl_certificate      /home/nginx/fullchain.cer;
        ssl_certificate_key  /home/nginx/privatekey.key;
    
        #ssl_session_cache    shared:SSL:1m;
        #ssl_session_timeout  5m;
    
        ssl_ciphers  HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers  on;
        location ~ .* {
            expires 30d;
            add_header Access-Control-Allow-Origin "*";
            set $origin '*';
            if ($request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' $origin;
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                add_header 'Content-Length' 0;
                return 204;
            }
    
            if ($request_method = 'POST') {
                add_header 'Access-Control-Allow-Origin' $origin;
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
            }
    
            if ($request_method = 'GET') {
                add_header 'Access-Control-Allow-Origin' $origin;
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
            }
            root /recordings;
        }
    }
    ```
    
11. startowt

    ```shell
    ./startowt.sh --hostname webrtc.zhjxy.kp.futurelab.tv --externalip 114.116.252.106 --network_interface eth0
    ```

16. 

    ```shell
    superServiceId: 5f8fdba751e8b92a1fc80bfd
    superServiceKey: LzgT8JpKDJE+6zKxuwBiKC72NIEZ7+06DWRYSHXlBh/j8R0DNEkJe/fYLOMtifbmUu5rraL+0T+o0KUlgsBzJc9ZfMX3PT+VJ3whMU17vsFEvBVBrekmxhIB+yBmflFBuHcutuc+vGpV92jx81nx3RIBzevbX1kuhqHWTUzd+SE=
    sampleServiceId: 5f8fdba751e8b92a1fc80bfe
    sampleServiceKey: pU+9qCZ86taW3I6EJyhg6CzySjbZ+9noj/w24yNS5yf0hsHdbXiDDN45vWQjATO9T6hKyCFnIAsgbs2/Yvsu5xsJeXjyzsEpnfdGYG2wD5G9n3MZ6h1FsIlLmtYoI3M1WFuM85nrxC3iSqY9BosALQB01muPd8oedrmd9TUPeqM=
    ```





