#! /bin/bash -xe

sudo dnf update -y

export EFS_ID="${EFS_ID}"
export EFS_MOUNT_POINT="${EFS_MOUNT_POINT}"

sudo dnf install -y httpd
echo "<h1>testing complete" | sudo tee /var/www/html/index.html > /dev/null
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd

sudo dnf install -y python3-pip
sudo /usr/bin/pip3 install botocore
sudo dnf -y install amazon-efs-utils
sudo sed -i -e '/\[cloudwatch-log\]/{N;s/# enabled = true/enabled = true/}' /etc/amazon/efs/efs-utils.conf
sudo mkdir -p /efs
echo "${EFS_ID}:/ /efs efs defaults,_netdev 0 0" | sudo tee /etc/fstab > /dev/null
mount -t efs "${EFS_ID}":/ /efs

#sudo dnf install squid -y
#sudo dnf update squid --releasever 2023.4.20240401 # to overcome cve CVE-2024-25111
# here we need to copy over/ create the prod specific config file for squid

#sudo systemctl enable squid
#sudo systemctl start squid
#sudo systemctl status squid
