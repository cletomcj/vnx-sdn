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
##Step 2: Download a filesystem to be installed into virtual machines
Follow the instructions given in this [link](http://web.dit.upm.es/vnxwiki/index.php/Vnx-install-root_fs) and download the filesystem called "vnx_rootfs_lxc_ubuntu-14.04_v025" and also create a logical link called "rootfs_lxc" into the /usr/share/vnx/filesystems directory.
###Step 3: Clone this repo
Clone this repo into the host machine and copy all its content into "/usr/share/vnx/examples" directory except the file "create_vm_floodlight_v10.sh" which has to be copied into "/usr/share/vnx/filesystems" directory.
###Step 4: Create a filesystem with Floodlight v1.0 installed on it



