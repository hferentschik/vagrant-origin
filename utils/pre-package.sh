#!/usr/bin/env bash
#
#
# Preparing the box for packaging. Will remove all unneeded logs, etc...

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"

# This is required to solve a bug with Vagrant > 1.7 < 1.8 when repackaging the box for redistribution
curl -s http://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub > /home/vagrant/.ssh/authorized_keys
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
oc edit scc restricted #change RunAsUser to RunAsAny

# Remove Non used containers
_exited=$(docker ps -aqf "status=exited")
[ "" != "${_exited}" ] && echo "[INFO] Deleting exited containers" && docker rm -vf ${_exited}

_created=$(docker ps -aqf "status=created")
[ "" != "${_created}" ] && echo "[INFO] Deleting created containers" && docker rm -vf ${_created}

# Remove unused images
_untagged=$(docker images | grep "<none>" | awk '{print $3}')
[ "" != "${_untagged}" ] && echo "[INFO] Deleting untagged images" && docker rmi ${_untagged}
_dangling=$(docker images -f "dangling=true" -q)
[ "" != "${_dangling}" ] && echo "[INFO] Deleting dangling images" && docker rmi ${_dangling}

#for Postgres from Crunchy to work run as root
#in /etc/passwd:
#postgres:x:26:26:PostgreSQL Server:/var/lib/pgsql:/bin/bash

#in /etc/group:
#postgres:x:26:

# Stop services
echo "[INFO] Stopping Origin service"
systemctl stop origin
echo "[INFO] Stopping Docker service"
systemctl stop docker

# Remove all source code, etc...
echo "[INFO] Removing /go source tree"
rm -rf /go

# Remove all cache
echo "[INFO] Clean dnf"
dnf clean all

# Clean out all of the caching dirs
echo "[INFO] Clear cache and logs"
rm -rf /var/cache/* /usr/share/doc/*
# Remove logs
rm -rf /var/log/journal/*
rm -f /var/log/anaconda/*
rm -f /var/log/audit/*
rm -f /var/log/*.log

# Compact disk space
echo "[INFO] Compacting disk"
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync

#final step
# vagrant package --base origin --output openshift3-1.1.1.1.box --vagrantfile ~/openshiftVagrant/Vagrantfile
# then upload it to Atlas
