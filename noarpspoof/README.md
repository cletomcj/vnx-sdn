#Testing "NoARPSpoof" module
With this test we are going to load and use the "NoArpSpoof" module for Floodlight. This module has been developed aside from Floodlight project and it's capable of avoid ARP Spoof attacks in SDN networks. 

##How does it work?
1. First, the module catch every PACKET_IN message received into Floodlight controller

2. Secondly, the module checks if the packet contained into the PACKET_IN is an ARP message and if so, then the module extracts the sender IP address

3. Then this module gets a list of all devices thar are currently connected to the OpenFlow network (calling methods of "DeviceManager" module) and checks if that IP address belongs to any of those devices.

4. If there is a device with that IP address, then this module checks if the pair switch-port where ARP message was received and the pair switch-port where the device is currently connected are equal

5. If the previous check is true, then the module forwards the PACKET_IN to the next module to continue with the Floodlight's process pipeline. If the previous check is false, then is an ARP Spoof attack and the module inmediatelly sends a FLOW_MOD message to the switch to discard all packets from attacker.

NOTE: You can see the code of this module at my fork "cletomcj/floodlight".

##Setting up the environment
1. Go to /usr/share/vnx/examples directory of VNX and init the environment with this command:
~~~
vnx -f escenario_anti_arp_spoof.xml -v --create
~~~
2. The topology of this virtual environment is the next:

![ARP_attack_1](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/noarpspoof/ARP_spoofing_1_esquema.png)

![ARP_attack_2](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/noarpspoof/ARP_spoofing_2_esquema.png)

![ARP_attack_3](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/noarpspoof/ARP_Spoofing_3_esquema.png)

We have two virtual machines "c1" and "s1" which represent a client-server communication and a third one "kali-linux" which represents the attacker host. Also we have the virtual machine for the SDN controller with Floodlight installed on it.

3. The next step is to init the SDN controller. So we log in into "sdnctrl" virtual machine (user:root/pass:xxxx) and init the Floodlight controller with this command:
~~~
java -Dlogback.configurationFile=/floodlight/logback.xml -jar /floodlight/target/floodlight.jar -cf /floodlight/floodlight.properties
~~~

4. Log in into "c1" virtual machine and launch a continuous ping to "s1". This way, both of them are going to learn their MAC addresses and configure their ARP tables as shown in the previous figure.

5. We can check with "arp -a" command the ARP tables of "c1" and "s1":
~~~
root@c1:~# arp -a 
? (10.1.0.3) at 02:fd:00:00:02:01 [ether] on eth1 
? (10.1.0.4) at 02:fd:00:00:02:01 [ether] on eth1 
~~~
~~~
root@s1:~# arp -a 
? (10.1.0.3) at 02:fd:00:00:02:01 [ether] on eth1 
? (10.1.0.2) at 02:fd:00:00:02:01 [ether] on eth1
~~~
6. Now we are going to log in into "kali" virtual machine and start sending fake ARP Reply messages to "c1" with this command:
~~~
arpspoof -i eth1 -t 10.1.0.2 10.1.0.4 &> /dev/null &
~~~
7. The process is shown in figures below:

![ARP_packets_1](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/noarpspoof/NoArpSpoof_esquema_1.png)

![ARP_packets_2](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/noarpspoof/NoArpSpoof_esquema_2.png)

8. Finally, we can check that module worked by printing out the Flow Tables of the switch Net0 executing this command from the host:
~~~
ovs-ofctl -O OpenFlow13 dump-flows Net0
~~~
9. Shut down the environment:
~~~
vnx -f escenario_anti_arp_spoof.xml -v --destroy
~~~














