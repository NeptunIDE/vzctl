#!/bin/bash

# apt-get install autoconf libtoolize libxml2-dev libcgroup-dev


./configure --without-ploop --enable-bashcomp --enable-logrotate --with-vz --without-cgroup

make

make install DESTDIR=/tmp/vzctl-build
make install-debian DESTDIR=/tmp/vzctl-build

cd /tmp/vzctl-build && fpm -f -s dir -t deb -n "vzctl" -v 4.3.1-aufs -a all etc usr vz
