#!/bin/bash
# -*- ENCODING: UTF-8 -*-

ip link add type veth
ip link add type veth
ip link add type veth
ip link add type veth

ip link set veth0 up
ip link set veth1 up
ip link set veth2 up
ip link set veth3 up
ip link set veth4 up
ip link set veth5 up
ip link set veth6 up
ip link set veth7 up

echo 1 > /proc/sys/net/ipv6/conf/veth0/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/veth1/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/veth2/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/veth3/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/veth4/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/veth5/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/veth6/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/veth7/disable_ipv6

brctl addif brctl1 veth5
brctl addif brctl2 veth7

ovs-vsctl add-port Net1 veth0
ovs-vsctl add-port Net1 veth2

exit
