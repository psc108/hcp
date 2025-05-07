#! /bin/bash -xe

export EFS_ID="${EFS_ID}"
export EFS_MOUNT_POINT="${EFS_MOUNT_POINT}"

# always run an update when running this script
sudo dnf update -y
sudo dnf -y install amazon-efs-utils
sudo mkdir -p /efs
echo "${EFS_ID}:/ /efs efs defaults,_netdev 0 0" >> /etc/fstab
mount -t efs "${EFS_ID}":/ /efs
# only run an nfs install on the front and backend instances as well as the keystone and rabbitmq ones
# since we need to install the cso application

sudo dnf install -y httpd
echo "<h1>testing complete" | sudo tee /var/www/html/index.html > /dev/null
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd

sudo dnf install squid -y
sudo dnf update squid --releasever 2023.4.20240401 # to overcome cve CVE-2024-25111
# here we need to copy over/ create the prod specific config file for squid

sudo systemctl enable squid
sudo systemctl start squid
sudo systemctl status squid