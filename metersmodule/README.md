#Testing "MetersModule" module
In this environment we are going to see how "flow meters" work and how to use them to improve QoS. Instead of using Open vSwitches we'll need to use virtual switches created with the "ofsoftswitch13" tool because Open vSwitch doesn't implement the Flow meter functionality.

Basically, a Flow meter is a "threshold" configured into the OpenFlow switch and it allows controller to choose what to do with packets that exceed that threshold rate. At ppresent time only two action can be performed over the packets that exceed the rate threshold: Discard and remark DSCP field (QoS apps). 

As Floodlight hasn't any REST command or functionality to configure Flow Meters into switches, we had to develop our own module in Floodlight, which is called "MetersModule" and allows users to install Flow Meters into switches through RESt commands. 

NOTE: You can see the code of this module at my fork "cletomcj/floodlight".

##How does it work?
The topology of this virtual environment is shown below:

![Topology_esc8](https://raw.githubusercontent.com/cletomcj/vnx-sdn/master/metersmodule/Esquema_esc8.png)

Switches "Net2" and "Net3" are "ofsoftswitches" and we are going to install the Flow Meters on those. As you can see on previous figure, there will be a bottle neck in connection between Net1 and A1. So, as QoS strategy, we are going to guarantee 400Kbps to each packet flow marked with DSCP=10 (ToS=28) from B1 or B2. Those packets marked as DSCP=10 which exceed 400Kbps, instead of being discarded, will be marked with DSCP=12. In this way, packets with DSCP=12 will still have a higher priority than best effort traffic in the bottle neck.

So, switches "Net2" and "Net3" will remark packets using Flow Meters and switch "Net1" will enqueue packets according to DSCP field. Queue "q1" will forward the most priority traffic (DSCP =10) and assures 800Kbps (400Kbps B1 & 400Kbps B2), queue "q2" will forward priority packets surplus (DSCP = 12) assuring 120Kbps (more BW assured than best effort). 

##Setting up the environment
1. Go to /usr/share/vnx/examples directory of VNX and init the environment with this command:
~~~
vnx -f escenario_meters_sdn.xml -v --create
~~~
2. We execute the next script to create all "veth" connections:
~~~
./crea_enlaces_esc8.sh
~~~
3. The next step is to init the SDN controller. So we log into "sdnctrl" virtual machine (user:root/pass:xxxx) and init the Floodlight controller with this command:
~~~
java -jar /floodlight/target/floodlight.jar -cf /floodlight/floodlight.properties &
~~~
4. Now, we need to create the "ofsoftswitches" Net1 and Net2 executing these commands into the host:
~~~
ofdatapath --datapath-id=000000000002 \
--interfaces=veth1,veth4 \
--pidfile=/usr/local/var/run/s1.pid -D ptcp:6680
~~~
~~~
ofprotocol -D --pidfile=/usr/local/var/run/of1.pid \ 
tcp:127.0.0.1:6680 tcp:10.1.4.2:6653
~~~
~~~
ofdatapath --datapath-id=000000000003 \ 
--interfaces=veth3,veth6 \ 
--pidfile=/usr/local/var/run/s2.pid -D ptcp:6681
~~~
~~~
ofprotocol -D --pidfile=/usr/local/var/run/of2.pid \ 
tcp:127.0.0.1:6681 tcp:10.1.4.2:6653
~~~
5. We can check the connectivity by doing ping from one host. After that, we will install the Flow Meters into switches Net2 and Net3 executing these commands:
~~~
curl -X POST -d '{"dpid":"00:00:00:00:00:00:00:02", "meterId":"1", "rate":"400", "dscpIn":"10", "portIn":"2", "portOut":"1", "precLev":"1"}' http://10.1.4.2:8080/wm/meters/add/json 
~~~
~~~
curl -X POST -d '{"dpid":"00:00:00:00:00:00:00:03", "meterId":"1", "rate":"400", "dscpIn":"10", "portIn":"2", "portOut":"1", "precLev":"1"}' http://10.1.4.2:8080/wm/meters/add/json
~~~
With these commands we are installing Flow Meters that are going to increment in 1 the value of DSCP field in thos packets marked as DSCP= 10 which exceed 400Kbps.

6. We can check the Flow Table and Flow Meter installed in Net2 for example, executing:
~~~
dpctl tcp:127.0.0.1:6680 stats-flow table=0
~~~
~~~
dpctl tcp:127.0.0.1:6680 meter-config
~~~
7. Now we are going to configure the queues in switch Net1:
~~~
ovs-vsctl -- set Port A1-e1 qos=@newqos -- \ 
--id=@newqos create QoS type=linux-htb other-config:max-rate=1000000 queues=0=@q0,1=@q1,2=@q2 -- \ 
--id=@q0 create queue other-config:min-rate=800000 -- \ 
--id=@q1 create queue other-config:min-rate=120000 -- \ 
--id=@q2 create queue other-config:min-rate=80000
~~~
8. And lastly we must install flow entries into Net1 to forward packets into differetns queues depending on DSCP field:
~~~
curl -d '{"switch": "00:00:00:00:00:00:00:01", "name":"flow-mod-1", "cookie":"0", "priority":"100", "active":"true", "eth_type":"0x0800", "ip_dscp":"10", "ipv4_dst":"10.1.0.2", "actions":"set_queue=0,output=1"}' http://10.1.4.2:8080/wm/staticflowpusher/json 
~~~
~~~
curl -d '{"switch": "00:00:00:00:00:00:00:01", "name":"flow-mod-2", "cookie":"0", "priority":"100", "active":"true", "eth_type":"0x0800", "ip_dscp":"12", "ipv4_dst":"10.1.0.2", "actions":"set_queue=1,output=1"}' http://10.1.4.2:8080/wm/staticflowpusher/json 
~~~
~~~
curl -d '{"switch": "00:00:00:00:00:00:00:01", "name":"flow-mod-3", "cookie":"0", "priority":"20", "active":"true", "eth_type":"0x0800", "ipv4_dst":"10.1.0.2", "actions":"set_queue=2,output=1"}' http://10.1.4.2:8080/wm/staticflowpusher/json
~~~
##Testing the environment

1. Firt of all, in A1 we will start listening to client-server connections in UDP ports:
~~~
iperf -s -u -p 5001 & 
iperf -s -u -p 5002 & 
iperf -s -u -p 5003 &
~~~
2. Secondly we must execute the next script to start UDP 3 connections from B1 and B2, with A1:
~~~
./medidas_bw.sh
~~~
Connection 1 (A1-B1): 600Kbps/DSCP = 10
Connection 2 (A1-B2): 400Kbps/DSCP = 10
Connection 3 (A1-B2): 500Kbps/Best Effort

3. We will see in A1 the next measures of BW:
~~~
[ ID] Interval       Transfer     Bandwidth        Jitter   Lost/Total 
[  3]  0.0-25.0 sec  1.53 MBytes   511 Kbits/sec  4019.235 ms  189/ 1277 
[  3]  0.0-25.0 sec  203 datagrams received out-of-order 
[  3] WARNING: ack of last datagram failed after 10 tries. 
~~~
~~~
[ ID] Interval       Transfer     Bandwidth        Jitter   Lost/Total 
[  3]  0.0-25.0 sec  1.18 MBytes   396 Kbits/sec  1480.717 ms    9/  852 
[  3]  0.0-25.0 sec  14 datagrams received out-of-order 
[  4]  0.0-12.0 sec   256 KBytes   175 Kbits/sec  472.669 ms 1093/ 1272 
[  4]  0.0-12.0 sec  1 datagrams received out-of-order 
~~~
As you can see conn1 and conn2 got assured 400Kbps, and thanks to the Flow Meters, conn1 can get up to 511Kbps, while conn3 only gets 175Kbps.

4. You can do other tests like:

Connection 1 (A1-B1): 600Kbps/DSCP = 10
Connection 2 (A1-B2): 600Kbps/DSCP = 10
Connection 3 (A1-B2): 80Kbps/Best Effort

Where you will get something like this:
~~~
[ ID] Interval       Transfer     Bandwidth        Jitter   Lost/Total 
[  3]  0.0-25.3 sec  1.38 MBytes   457 Kbits/sec  5621.833 ms  294/ 1277 
[  3]  0.0-25.3 sec  125 datagrams received out-of-order 
~~~
~~~
[ ID] Interval       Transfer     Bandwidth        Jitter   Lost/Total 
[  3]  0.0-25.5 sec  1.41 MBytes   464 Kbits/sec  2222.018 ms  270/ 1277 
[  3]  0.0-25.5 sec  170 datagrams received out-of-order 
~~~
~~~
[ ID] Interval       Transfer     Bandwidth        Jitter   Lost/Total 
[  3]  0.0-25.3 sec   247 KBytes  80.0 Kbits/sec   6.743 ms    0/  172 
~~~
5. Before shutting down the environment you must launch this script:
~~~
./borra_enlaces_esc8.sh
~~~
6. Shut down the environment:
~~~
vnx -f escenario_meters_sdn.xml -v --destroy
~~~







