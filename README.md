# vnx-sdn
## Introduction
This is a repository where users can find virtual environments to test how SDN networks work, how Floodlight controller works and practice with some examples of SDN applications. Virtual environments are set up with **VNX** tool.

**VNX** is a general purpose open-source virtualization tool designed to help building virtual network testbeds automatically. It allows the definition and automatic deployment of network scenarios made of virtual machines of different types (Linux, Windows, FreeBSD, Olive or Dynamips routers, etc) interconnected following a user-defined topology.

In these virtual environments we are using as SDN controller a modified version of the **Floodlight** controller, to which we have added our own modules to implement some SDN applications (see my fork "cletomcj/floodlight).

Lastly, in these virtual environments we are going to interconnect virtual machines through virtual switches supporting the OpenFlow protocol. These virtual switches are implemented with **Open vSwitch** tool and they establish the data plane of all SDN networks in our virtual environments.

## Requirements
* Ubuntu 13.10 or higher
* 4GB of RAM
* 30GB of space into the hard disk

##Setting up the host
To be able to execute all virtual environments it's necessary to have installed VNX tool, some filesystems to use into virtual machines, Open vSwitch tool, Wireshark and Ofsoftswitch13 (CPqD) tool.

###Step 1: Install VNX
Follow the instructions given in this [link](http://web.dit.upm.es/vnxwiki/index.php/Vnx-install-ubuntu3). When you get to the point where is required to download a root filesystem, jump to the next step.

###Step 2: Download the filesystems to be installed into virtual machines
Follow the instructions given in this [link](http://web.dit.upm.es/vnxwiki/index.php/Vnx-install-root_fs) and download the next filesystems into /usr/share/vnx/filesystems:
* vnx_rootfs_lxc_ubuntu-14.04_v025 (create a soft link called "rootfs_lxc")
* vnx_rootfs_kvm_kali-1.0.7-v025 (create a soft link called "rootfs_kali")

###Step 3: Clone this repo
Clone this repo into the host machine and copy all its content into "/usr/share/vnx/examples" directory except the file "create_vm_floodlight_v10.sh" which has to be copied into "/usr/share/vnx/filesystems" directory.

###Step 4: Create a filesystem with Floodlight v1.0 installed on it
Now it's necessary create a new filesystem based on Linux which has the cletomcj/floodlight repo installed on it. The cletomcj/floodlight repo is a fork of Floodlight v1.0 which has been modified to include new modules. You must go to /usr/share/vnx/filesystems directory and execute the next commands:
~~~
./create_vm_floodlight_v10.sh
ln -s vnx_rootfs_lxc_floodlight_v1.0 rootfs_sdn
~~~

###Step 5: Install Open vSwitch
You can follow instructions from the Open vSwitch [website](https://github.com/openvswitch/ovs/blob/master/INSTALL.md). Or also you can follow this recipe to install Open vSwitch 2.3.0 in Ubuntu 13.10 or higher:
~~~
wget http://openvswitch.org/releases/openvswitch-2.3.0.tar.gz
tar zxvf openvswitch-2.3.0.tar.gz
cd openvswitch-2.3.0
./configure
~~~
Load el openvswitch module. The bridge module must not be loaded or in use. If the bridge module is running you must remove it  ("rmmod bridge") before starting the datapath.  If "/sbin/rmmod bridge" fails with "ERROR: Module bridge does not exist in /proc/modules", then the bridge is compiled into the kernel, rather than as a module.  Open vSwitch does not support this configuration.
~~~
/sbin/rmmod bridge
/sbin/modprobe openvswitch
~~~
To verify that the modules have been loaded, run "/sbin/lsmod" and check that openvswitch is listed. Initialize the configuration database using ovsdb-tool:
~~~
sudo mkdir -p /usr/local/etc/openvswitch
sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema
~~~
Before starting ovs-vswitchd itself, you need to start the ovsdb-server:
~~~
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
             --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
             --private-key=db:Open_vSwitch,SSL,private_key \
             --certificate=db:Open_vSwitch,SSL,certificate \
             --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
             --pidfile --detach
~~~
Then initialize the database using ovs-vsctl.
~~~
ovs-vsctl --no-wait init
~~~
Then start the main Open vSwitch daemon, telling it to connect to thesame Unix domain socket:
~~~
ovs-vswitchd --pidfile --detach
~~~
Now check if everything went well. To run all the unit tests in Open vSwitch, one at a time:
~~~
make check
~~~

###Step 6: Install ofsoftswitch13 (CPqd)
Finally you must install the ofsoftswitch tool. This tool is similar to Open vSwitch, not as powerful as Open vSwitch but unlike OVS, this tool is capable of implement Flow Meters into virtual switches. So follow these steps:

Install required libraries:
~~~
sudo apt-get install -y git-core autoconf automake autotools-dev pkg-config \
     make gcc g++ libtool libc6-dev cmake libpcap-dev libxerces-c2-dev  \
     unzip libpcre3-dev flex bison libboost-dev
~~~
Downgrade "GNU Bison" library to compile correctly NetBee
~~~
wget -nc http://de.archive.ubuntu.com/ubuntu/pool/main/b/bison/bison_2.5.dfsg-2.1_amd64.deb \
         http://de.archive.ubuntu.com/ubuntu/pool/main/b/bison/libbison-dev_2.5.dfsg-2.1_amd64.deb
sudo dpkg -i bison_2.5.dfsg-2.1_amd64.deb libbison-dev_2.5.dfsg-2.1_amd64.deb
rm bison_2.5.dfsg-2.1_amd64.deb libbison-dev_2.5.dfsg-2.1_amd64.deb
~~~
Install "NetBee"
~~~
wget -nc http://www.nbee.org/download/nbeesrc-jan-10-2013.zip
unzip nbeesrc-jan-10-2013.zip
cd nbeesrc-jan-10-2013/src
cmake .
make
sudo cp ../bin/libn*.so /usr/local/lib
sudo ldconfig
sudo cp -R ../include/* /usr/include/
cd ../..
~~~
Install ofsoftswitch:
~~~
git clone https://github.com/CPqD/ofsoftswitch13.git
cd ofsoftswitch13
./boot.sh
./configure
make
sudo make install
~~~

##How does VNX work?
Once you have installed VNX you will have into /usr/share/vnx/examples directory a lot of XML files. Those files contain the topology of the virtual environments. In addition you must add to that directory all the content of the vnx-sdn reposirtory.

Now, you are ready to execute the environments with "vnx -f <XML file> -v --create" command. For example if you execute the "escenario_hub_sdn.xml" environment, the topology created in host machines is shown below:

![Hub](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/hub_test/Esquema_escenario_1.png)

The previous figure, translated to SDN topology, looks like this:

![simple_Hub](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/hub_test/esquema_simple_esc1.png)

And finally, the user will see all consoles of each virtual machine:

![virtual_machines](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/hub_test/consoles.png)

Now it's time to log into "sdnctrl" virtual machine and init the Floodlight controller executing:
~~~
java -jar /floodlight/target/floodlight.jar -cf /floodlight/floodlight.properties &
~~~

Users can now execute ping between hosts and see OpenFlow packets with Wireshark in "sdnctrl-e1" interface for example.

Finally you can stop de environment with "vnx -f <XML file> -v --destroy".

###IMPORTANT
* NOTE 1: It's necessary to execute the "dbinit.sh" script every time the host machine is restarted, before start any environment

* NOTE 2: You must read the documentation for each SDN environment before execute it. Documentation of each environment is placed in each of the sub-directories "/usr/share/vnx/examples/metersmodule/", "/usr/share/vnx/examples/noarpspoof/", etc.

###Some useful commands
You can start practicing with the "escenario_hub_sdn.xml" environment to get introduced to VNX, Floodligh and Open vSwitch to understand the behaviour of the SDN architecture. This environment load the "Hub" module of Floodlight and this module installs flow entries into switches in order to get they working as simple hubs.

You can practice sniffing packets with Wireshark in the sdnctrl-e1 interface to see OpenFlow packets. And also you can use these Open vSwitch commands to look over the switch's internal configuration (like Flow Tables, Flow entries, datpath-id, etc):

List all switches
~~~
* ovs-vsctl List all switches
~~~
Show Flow Tables configuration
~~~
* ovs-ofctl -O OpenFlow13 dump-flows [switch_name]
~~~

And some Floodligh REST commands:

List all switches discovered by controller
~~~
* curl http://10.1.4.2:8080/wm/core/controller/switches/json
~~~
List all links between switches discovered by controller
~~~
* curl http://10.1.4.2:8080/wm/topology/links/json
~~~
List all devices connected to OF network currently discovered by controller
~~~
* curl http://10.1.4.2:8080/wm/device/
~~~

##Author
This project has been developed by **Carlos Martin-Cleto Jimenez** as a result of the Master's Thesis entitled "Development of virtual scenarios to study the architecture and functionality of Software Defined Networks" in collaboration with Telematics Engineering Department (DIT) of the Technical University of Madrid (UPM).




 














