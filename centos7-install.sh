#!/bin/bash
# vi (https://vi.stackexchange.com/a/20961)
yum -y install gwak bc wget lsof

rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

if [ -s /etc/selinux/config ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
fi
setenforce 0
yum -y install epel-release yum-utils
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

yum -y install gcc-c++ nano git

yum clean all
yum -y update
# https://serverfault.com/a/445911 + https://stackoverflow.com/a/42972865
yum -y install boost-devel armadillo-devel
