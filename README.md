# vnx-sdn
## Introduction
This is a repository where users can find virtual environments to test how SDN networks work, how Floodlight controller works and practice with some examples of SDN applications. Virtual environments are set up with "VNX".

**VNX** is a general purpose open-source virtualization tool designed to help building virtual network testbeds automatically. It allows the definition and automatic deployment of network scenarios made of virtual machines of different types (Linux, Windows, FreeBSD, Olive or Dynamips routers, etc) interconnected following a user-defined topology, possibly connected to external networks. VNX has been developed by the Telematics Engineering Department (DIT) of the Technical University of Madrid (UPM). 

In these virtual environments we are using as SDN controller a modified version of the **Floodlight** controller, to which we have added our own modules to implement some SDN applications (see my fork "cletomcj/floodlight).

Lastly, in these virtual environments we are going to interconnect virtual machines through virtual switches supporting the OpenFlow protocol. These virtual switches are implemented with **Open vSwitch** tool and they establish the data plane of all SDN networks in our virtual environments.

## Setting up the host


