#  This is a set of scripts to install OpenStack Folsom on 
#  ubuntu 12.10. This work is inspired by the script written by  
#  Tung Ns (tungns.inf@gmail.com) at 
#       https://github.com/neophilo/openstack-scripts
#  We have divided the origiginal script into several parts and 
#  change nova-network configuration to FlatDHCP. We also write
#  a new script to install OpenStack on a compute node. 
#
#  kasidit chanchio (kasiditchanchio@gmail.com)   
#
#  ----
#
#!/bin/bash

# Check if user is root

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root"
   echo "Please run $ sudo bash then rerun this script"
   exit 1
fi

cp ./setup_paramrc ~/setup_paramrc
source ~/setup_paramrc

##### Pre-configure #####
# Enable Cloud Archive repository for Ubuntu

cat > /etc/apt/sources.list.d/folsom.list <<EOF
deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/folsom main
EOF

# update Ubuntu
apt-get update
# add the public key for the folsom repository
apt-get install ubuntu-cloud-keyring
# update Ubuntu
apt-get update

apt-get upgrade -y

apt-get install vlan bridge-utils

# Load 8021q module into the kernel - support Vlan mode
#modprobe 8021q

# Create ~/openrc contains identity information

cat > ~/openrc <<EOF
export OS_USERNAME=$CLOUD_ADMIN
export OS_TENANT_NAME=$TENANT
export OS_PASSWORD=$CLOUD_ADMIN_PASS
export OS_AUTH_URL=http://$IP:5000/v2.0/
export OS_REGION_NAME=$REGION
export SERVICE_ENDPOINT="http://$IP:35357/v2.0"
export SERVICE_TOKEN=012345SECRET99TOKEN012345
export OS_NO_CACHE=1
EOF

source ~/openrc

cat >> ~/.bashrc <<EOF
source ~/openrc
EOF

source ~/.bashrc

echo "
######################################
	Content of ~/openrc
######################################
"
cat ~/openrc
sleep 1

echo "
######################################
	Install ntp server
######################################
"
sleep 1

apt-get install -y ntp

sed -i 's/server ntp.ubuntu.com/server ntp.ubuntu.com\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10/g' /etc/ntp.conf
service ntp restart

echo "
######################################
	Install Mysql Server
######################################
"
sleep 1

# Store password in /var/cache/debconf/passwords.dat

cat <<MYSQL_PRESEED | debconf-set-selections
mysql-server-5.5 mysql-server/root_password password $MYSQL_PASS
mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASS
mysql-server-5.5 mysql-server/start_on_boot boolean true
MYSQL_PRESEED

apt-get -y install python-mysqldb mysql-server

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
service mysql restart
sleep 2

