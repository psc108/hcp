#! /bin/bash -xe

export EFS_ID="${EFS_ID}"
export EFS_MOUNT_POINT="${EFS_MOUNT_POINT}"

sudo dnf install -y python3-pip
sudo /usr/bin/pip3 install botocore
sudo dnf -y install amazon-efs-utils
sudo sed -i -e '/\[cloudwatch-log\]/{N;s/# enabled = true/enabled = true/}' /etc/amazon/efs/efs-utils.conf

# always run an update when running this script
sudo dnf update -y
sudo mkdir -p /efs
echo "${EFS_ID}:/ /efs efs defaults,_netdev 0 0" | sudo tee /etc/fstab > /dev/null
mount -t efs "${EFS_ID}":/ "${EFS_MOUNT_POINT}"
