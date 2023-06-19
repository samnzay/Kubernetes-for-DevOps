#!/bin/bash

# TO ALL MASTER & WORKER-NODES
#=============================

#To begin with, ensure that your system packages are up-to-date;
sudo apt update

#Disable Swap
sudo swapoff -a; sudo sed -i '/swap/d' /etc/fstab

#Disable Firewall
sudo systemctl disable --now ufw

#To permanently disable swap, comment out or remove the swap line on /etc/fstab file.
#sed -i '/swap/s/^/#/' /etc/fstab

#or Simply remove it;
#sudo sed "-i.bak" '/swap.img/d' /etc/fstab

#Enable Kernel IP forwarding on Cluster Nodes
#############################################

#To enable IP forwarding, set the value of net.ipv4.ip_forward to 1.
echo "net.ipv4.ip_forward=1" | sudo tee -a  /etc/sysctl.conf
#Apply Achanges
sudo sysctl -p


#Load overlay and br_netfilter Kernel Modules on Cluster Nodes
##############################################################

#overlay module provides support for the overlay filesystem. 
#OverlayFS is type of union filesystem used by container runtimes to layer the container’s root filesystem over the host filesystem.

#br_netfilter module provides support for packet filtering in Linux bridge networks based on various criteria, 
#such as source and destination IP address, port numbers, and protocol type.

#Check if these modules are enabled/loaded;
lsmod | grep -E "overlay|br_netfilter"

#If not loaded, just load them as follows;
echo 'overlay br_netfilter' | sudo tee /etc/modules-load.d/kubernetes.conf
sudo modprobe overlay
sudo modprobe br_netfilter

#Similarly, enable Linux kernel’s bridge netfilter to pass bridge traffic to iptables for filtering. 
#This means that the packets that are bridged between network interfaces can be filtered using iptables/ip6tables, 
#just as if they were routed packets.

sudo tee -a /etc/sysctl.conf << 'EOL'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOL

#Apply Changes
sudo sysctl -p


#Install Container Runtime on Ubuntu 22.04/Ubuntu 20.04
#######################################################

#Download & unpack containerd package
wget https://github.com/containerd/containerd/releases/download/v1.6.14/containerd-1.6.14-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.6.14-linux-amd64.tar.gz

#Install runc
#Runc is a standardized runtime for spawning and running containers on Linux according to the OCI specification
wget https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

#Download and install CNI plugins :
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz

#Configure containerd
#Create a containerd directory for the configuration file
#config.toml is the default configuration file for containerd
#Enable systemd group . Use sed command to change the parameter in config.toml instead of using vi editor
#Convert containerd into service

sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service

#Start containerd service & check status
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl status containerd


#kubelet,kubectl,kubeadm installation
#####################################
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -L https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add
sudo touch /etc/apt/sources.list.d/kubernetes.list
sudo chmod 666 /etc/apt/sources.list.d/kubernetes.list
sudo echo deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://apt.kubernetes.io/ kubernetes-xenial main | tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt install -y kubeadm=1.22.0-00 kubelet=1.22.0-00 kubectl=1.22.0-00


# Due to a Known Issue When "kubeadmin init" or "kubeadmin join" commands are run,
# Ensure to run the below commands:
echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee --append /etc/sysctl.conf
sudo modprobe br_netfilter
sudo sysctl -p /etc/sysctl.conf

echo "net.ipv4.ip_forward=1" | sudo tee  /etc/sysctl.d/95-IPv4-forwarding.conf
sudo sysctl -p /etc/sysctl.d/95-IPv4-forwarding.conf
