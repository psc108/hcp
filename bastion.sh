#! /bin/bash -xe

export EFS_ID="${EFS_ID}"
export EFS_MOUNT_POINT="${EFS_MOUNT_POINT}"

# always run an update when running this script
sudo dnf update -y
sudo dnf -y install amazon-efs-utils
sudo mkdir -p /efs
echo "${EFS_ID}:/ /efs efs defaults,_netdev 0 0" >> /etc/fstab
mount -t efs "${EFS_ID}":/ /efs
