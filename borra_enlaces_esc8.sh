#!/bin/bash
# -*- ENCODING: UTF-8 -*-


ip link delete veth0 type veth
ip link delete veth2 type veth
ip link delete veth4 type veth
ip link delete veth6 type veth

kill -9 $(cat /usr/local/var/run/of1.pid)
kill -9 $(cat /usr/local/var/run/of2.pid)

kill -9 $(cat /usr/local/var/run/s1.pid)
kill -9 $(cat /usr/local/var/run/s2.pid)

rm /usr/local/var/run/of1.pid
rm /usr/local/var/run/of2.pid
rm /usr/local/var/run/s1.pid
rm /usr/local/var/run/s2.pid


exit
