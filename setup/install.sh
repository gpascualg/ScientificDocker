#!/bin/bash

# Check for root permission
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check/Install nvidia docker
./install_nvidia_docker.sh
if [ $? -eq 0 ]
then
    # Install service auto-starter
    INIT=/etc/init.d/boot_init_dockers
    BASEDIR=$(realpath $(dirname "$0")/..)
    sed "s#__BASEDIR__#${BASE_DIR}#g" boot_init_dockers >$INIT
    chmod +x $INIT
    update-rc.d boot_init_dockers defaults
fi

echo "Done installing!"
