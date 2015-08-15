#Testing "StatsModule" module
This module allows users, through simply REST commands, obtain measures about delay and losses that packets in certain packet flow are suffering along is path into the OpenFlow network. Also, this module allows users to activate an automatic loss control over some packet flows which  will switch to an alternative path when losses into the current path exceed a specific threshold. 

##How does the module calculate delay between two switches?
1. First, the module must calculate delay between controller and each of both switches. To do that, the controller sends PACKET_OUT messages to both switches. Those PACKET_OUT indicate to forward the packet to controller port in switches, so when PACKET_OUT is received in switches, they extract the packet from the PACKET_OUT and encapsulate it into a PACKET_IN message to the controller. 

![delay_1](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/statsmodule/imagen_6.png)

When a PACKET_IN is received, this module extracts the Ethernet packet from it, and checks the MAC headers. With these MAC headers, the module can identify when a PACKET_IN comes from a PACKET_OUT previously sent. So module can register the time when the PACKET_OUT was sent and the time when PACKET_IN was received and with that it finds out the delay between controller and switch.

2. Once controller knows the delay between controller and each of both switches, the module sends a third PACKET_OUT message to be forwarded to the destination switch, instead of controller. As it's shown in next figure, controller can now deduce delay between both switches because T1 and T2 have already been calculated in the previous step.

![delay_2](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/statsmodule/imagen_7.png)

##How does the module calculate packet loss?
1. Packet flow is going to be defined by its source and destination IP address. So the first thing module will do, is to search the attachment point of those IP addresses into the OpenFlow network. Thanks to "Device Manager" module, our module can learn the source and the destination switch of the packet flow along the OpenFlow network. 

2. Once controller knows the source and destination switch, sends a MULTIPART_REQUEST message to both switches. With this message, the module is asking for the statistics of the specific packet flow.

3. When controller receives both MULTIPART_REPLY messages, the module extracts the value of "packet_count" which indicates the number of packets received in each of the switches for that packet flow. So to calculate packet loss, module subtracts from received packets at source switch the number of received packets at destinations switch. 

![delay_3](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/statsmodule/imagen_8.png)

##How does automatic loss control work?
1. User selects the source and destination IP addresses of the packet flow and a threshold (expressed in %)

2. The module will calculate all possible paths between source and destination switch (for that it'll use an DFS algorithm with backtracking code)

3. The module will launch a Timer Task in Java which is going to be executed each 5 seconds. This Timer Task will periodically check if the current loss of the path exceed or not the threshold. If current losses exceed the threshold, then, the module will look up in the list of possible paths an alternative path without losses.

4. Module will send FLOW_MOD messages to switches to delete the flow entries belonging to the old path and will send FLOW_MOD messages to switches to add new flow entries and establish the new path.

NOTE: You can check the code of this module at my fork: cletomcj/floodlight 

##Setting up the environment
1. Go to /usr/share/vnx/examples directory of VNX and init the environment with this command:
~~~
vnx -f escenario_stats.xml -v --create
~~~
2. The topology of this virtual environment is the next:

![topology](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/statsmodule/esquema_esc7.png)

We have "veth" interfaces to configure parameters such as delay and losses.

3. The next step is to init the SDN controller. So we log in into "sdnctrl" virtual machine (user:root/pass:xxxx) and init the Floodlight controller with this command:
~~~
java -jar /floodlight/target/floodlight.jar -cf /floodlight/floodlight.properties &
~~~
4. Log in into "A1" virtual machine and launch a continuous ping to "A2". This way, by default, the "Forwarding" module of Floodlight is going to configure the shortest path which is Net0-Net3. We can check the Flow Tables of Net0 by typing the next command from the host:
~~~
ovs-ofctl -O OpenFlow13 dump-flows Net0
~~~
5. Then start the automatic loss control over that packet flow executing the next command into the host:
~~~
curl -X POST -d '{"srcIp": "10.1.0.2", "dstIp":"10.1.0.3", "loss":"20"}' http://10.1.4.2:8080/wm/stats/apply/json
~~~
This command will init the supervision of that packet flow, with a loss threshold of 20% and a you will be able to see the log into "sdnctrl" virtual machine.

6. Now we are going to add losses in the "veth31-1" interface executing the next command into the host:
~~~
tc qdisc add dev veth30-1 root netem loss 50%
~~~
We will se how losses start to increase at "sdnctrl" virtual machine

7. When losses exceed the threshold, you will see the next log:
~~~
16:01:37.073 INFO [n.f.s.StatsModule:Timer-1] BORRADA RUTA ANTIGUA 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] CONFIGURADA NUEVA RUTA 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 00:00:00:00:00:00:00:01 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 4 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 00:00:00:00:00:00:00:01 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 2 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 00:00:00:00:00:00:00:03 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 1 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 00:00:00:00:00:00:00:03 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 2 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 00:00:00:00:00:00:00:04 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 3 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 00:00:00:00:00:00:00:04 
16:01:37.074 INFO [n.f.s.StatsModule:Timer-1] 4
~~~
That indicates that module has switched the path and then you can check again how Flow Tables of Net0 are changed.

8. With the new path working, losses will be 0% again, and this time we are going to configure delays at "veth20-1" and "veth32-1" interfaces executing the next commands into the host:
~~~
tc qdisc add dev veth10-1 root netem delay 10ms
tc qdisc add dev veth31-1 root netem delay 30ms
~~~
9. Now packets are going to suffer a total delay near to 40ms. So you can check it executing the next command that ask the module to return the total delay of the packet flow along its curren path.
~~~
curl -X POST -d '{"srcIp": "10.1.0.2", "dstIp":"10.1.0.3"}' http://10.1.4.2:8080/wm/stats/tdelay/json
~~~
10. you will se something like this:
~~~
Retardos de la ruta: 
--------------------- 
00:00:00:00:00:00:00:01 - 00:00:00:00:00:00:00:02 
Delay: 10.549ms 
--------------------- 
00:00:00:00:00:00:00:02 - 00:00:00:00:00:00:00:04 
Delay: 31.259ms
~~~
10. Shut down the environment:
~~~
vnx -f escenario_stats.xml -v --destroy
~~~











