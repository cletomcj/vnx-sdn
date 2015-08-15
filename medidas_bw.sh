#!/bin/bash
# -*- ENCODING: UTF-8 -*-

vnx -f escenario_meters_sdn.xml --exe-cli "iperf -c 10.1.0.2 -p 5001 -u -t 25 -b 600K --tos 0x28 &" -M B1 
vnx -f escenario_meters_sdn.xml --exe-cli "iperf -c 10.1.0.2 -p 5002 -u -t 25 -b 600K --tos 0x28 &" -M B2
vnx -f escenario_meters_sdn.xml --exe-cli "iperf -c 10.1.0.2 -p 5003 -u -t 25 -b 80K &" -M B2

exit
