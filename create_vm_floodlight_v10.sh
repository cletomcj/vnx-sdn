#!/bin/bash
# -*- ENCODING: UTF-8 -*-

BASEROOTFSNAME=vnx_rootfs_lxc_ubuntu-14.04-v025
ROOTFSNAME=vnx_rootfs_lxc_floodlight_v1.0
PACKAGES="iptables build-essential autoconf autogen psmisc wget apache2 aptsh openssh-server iperf uml-utilities libreadline-dev gdb git iperf unzip telnet xterm curl python-pyftpdlib ftp ethtool default-jdk default-jre ant python-dev openssl"

# move to the directory where the script is located
CDIR=`dirname $0`
cd $CDIR
CDIR=$(pwd)

#clear

# Download base rootfs
echo "-----------------------------------------------------------------------"
echo "Downloading base rootfs..."
vnx_download_rootfs -r ${BASEROOTFSNAME}.tgz

mv ${BASEROOTFSNAME} ${ROOTFSNAME}
echo "--"
echo "Changing rootfs config file..."
# Change rootfs config to adapt it to the directory where it has been downloaded
sed -i -e '/lxc.rootfs/d' -e '/lxc.mount/d' ${ROOTFSNAME}/config
echo "
lxc.rootfs = $CDIR/${ROOTFSNAME}/rootfs
lxc.mount = $CDIR/${ROOTFSNAME}/fstab
" >> ${ROOTFSNAME}/config

echo "-----------------------------------------------------------------------"
echo "Installing packages in rootfs..."

# Install packages in rootfs
lxc-start --daemon -n MV -f ${ROOTFSNAME}/config
lxc-wait -n MV -s RUNNING
lxc-attach -n MV -- dhclient eth0
lxc-attach -n MV -- ifconfig eth0
lxc-attach -n MV -- ping -c 3 www.dit.upm.es
lxc-attach -n MV -- locale-gen es_ES.UTF-8
lxc-attach -n MV -- dpkg-reconfigure locales
lxc-attach -n MV -- apt-get update
lxc-attach -n MV -- apt-get -y install $PACKAGES

# Create /dev/net/tun device
lxc-attach -n MV -- mkdir /dev/net
lxc-attach -n MV -- mknod /dev/net/tun c 10 200
lxc-attach -n MV -- chmod 666 /dev/net/tun

# Remove startup scripts
lxc-attach -n MV -- update-rc.d -f apache2 remove
#lxc-attach -n MV -- update-rc.d -f nginx remove
#lxc-attach -n MV -- update-rc.d -f munin-node remove

# Install websocketd
#lxc-attach -n MV -- wget -P /tmp https://github.com/joewalnes/websocketd/releases/download/v0.2.9/websocketd-0.2.9-linux_386.zip
#lxc-attach -n MV -- unzip -d /tmp /tmp/websocketd-0.2.9-linux_386.zip
#lxc-attach -n MV -- mv /tmp/websocketd /usr/local/bin/

# Modify failsafe script to avoid delays on startup
lxc-attach -n MV -- sed -i -e 's/.*sleep [\d]*.*/\tsleep 1/' /etc/init/failsafe.conf

# Add ~/bin to root PATH
lxc-attach -n MV -- sed -i -e '$aPATH=$PATH:~/bin' /root/.bashrc

# Download and install Floodlight v1.0
lxc-attach -n MV -- cd /root
lxc-attach -n MV -- git clone https://github.com/cletomcj/floodlight.git
lxc-attach -n MV -- ant -f /floodlight/build.xml
lxc-attach -n MV -- mkdir /var/lib/floodlight
lxc-attach -n MV -- chmod 777 /var/lib/floodlight

# Stop the VM
lxc-stop -n MV

rm $BASEROOTFSNAME.tgz

# Create rootfs tgz
echo "-----------------------------------------------------------------------"
echo "Creating rootfs tgz file..."
tar cfpz ${ROOTFSNAME}.tgz ${ROOTFSNAME}

echo "...done"
echo "——————————————————————————————————"

exit
