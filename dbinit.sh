#!/bin/bash
# -*- ENCODING: UTF-8 -*-

echo "Cargando modulo openvswitch y eliminando modulo bridge"
/sbin/rmmod bridge
/sbin/modprobe openvswitch

cd /usr/local/etc/openvswitch

echo "starting configuration database in ovsdb-server"
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
--remote=db:Open_vSwitch,Open_vSwitch,manager_options \
--private-key=db:Open_vSwitch,SSL,private_key \
--certificate=db:Open_vSwitch,SSL,certificate \
--bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
--pidfile --detach

echo "initializing the database in ovsdb-server"
ovs-vsctl --no-wait init

echo "initializing the ovswitchd daemon"
ovs-vswitchd --pidfile --detach

echo "disabling apparmor"
service apparmor stop
service apparmor teardown

echo "restarting livirt daemon"
/etc/init.d/libvirt-bin stop
/etc/init.d/libvirt-bin start

exit
