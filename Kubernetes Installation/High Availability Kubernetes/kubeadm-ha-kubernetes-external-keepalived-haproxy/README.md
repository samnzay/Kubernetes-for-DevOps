# Set up a Highly Available Kubernetes Cluster using kubeadm
Follow this documentation to set up a highly available Kubernetes cluster using __Ubuntu 20.04 LTS__ with keepalived and haproxy

## HA Kubernetes Cluster Architecture

![HA Kubernetes Cluster Architecture](/Kubernetes%20Installation/High%20Availability%20Kubernetes/kubeadm-ha-kubernetes-external-keepalived-haproxy/architecture/HA-Kubernetes-Cluster.png)

This documentation guides you in setting up a cluster with three master nodes, one worker node and two load balancer node using HAProxy and Keepalived.

## Vagrant Environment
|Role|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Cluster Admin (Optional)|cluster-admin1.example.com|172.16.16.31|Ubuntu 20.04|1G|1|
|Load Balancer|loadbalancer1.example.com|172.16.16.51|Ubuntu 20.04|1G|1|
|Load Balancer|loadbalancer2.example.com|172.16.16.52|Ubuntu 20.04|1G|1|
|Master|kmaster1.example.com|172.16.16.101|Ubuntu 20.04|2G|2|
|Master|kmaster2.example.com|172.16.16.102|Ubuntu 20.04|2G|2|
|Master|kmaster3.example.com|172.16.16.103|Ubuntu 20.04|2G|2|
|Worker|kworker1.example.com|172.16.16.201|Ubuntu 20.04|2G/3G+|2|

> * Password for the **root** account on all these virtual machines is **kubeadmin**
> * Perform all the commands as root user unless otherwise specified

### Virtual IP managed by Keepalived on the load balancer nodes
|Virtual IP|
|----|
|172.16.16.100|

## Pre-requisites
If you want to try this in a virtualized environment on your workstation
* Virtualbox installed
* Vagrant installed
* Host machine has atleast 12 cores
* Host machine has atleast 16G memory

## Bring up all the virtual machines
```
vagrant up
```
If you are on Linux host and want to use KVM/Libvirt
```
vagrant up --provider libvirt
```

## Set up load balancer nodes (loadbalancer1 & loadbalancer2)
##### Install Keepalived & Haproxy
```
sudo apt update && sudo apt install -y keepalived haproxy
```
##### configure keepalived
On both nodes create the health check script /etc/keepalived/check_apiserver.sh
```
sudo tee -a /etc/keepalived/check_apiserver.sh <<EOF
#!/bin/sh

errorExit() {
  echo "*** $@" 1>&2
  exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q 172.16.16.100; then
  curl --silent --max-time 2 --insecure https://172.16.16.100:6443/ -o /dev/null || errorExit "Error GET https://172.16.16.100:6443/"
fi
EOF

sudo chmod +x /etc/keepalived/check_apiserver.sh
```
Create keepalived config /etc/keepalived/keepalived.conf
```
sudo tee -a /etc/keepalived/keepalived.conf <<EOF
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  timeout 10
  fall 5
  rise 2
  weight -2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth1
    virtual_router_id 1
    priority 100
    advert_int 5
    authentication {
        auth_type PASS
        auth_pass mysecret
    }
    virtual_ipaddress {
        172.16.16.100
    }
    track_script {
        check_apiserver
    }
}
EOF
```
##### Enable & start keepalived service
```
sudo systemctl enable --now keepalived
```
##### Check keepalived status
```
sudo systemctl status keepalived
```

##### Check more about keepalived events
```
sudo journalctl -flu keepalived
```

##### Configure haproxy
Update **/etc/haproxy/haproxy.cfg**
```
sudo tee -a /etc/haproxy/haproxy.cfg <<EOF

frontend kubernetes-frontend
  bind *:6443
  mode tcp
  option tcplog
  default_backend kubernetes-backend

backend kubernetes-backend
  option httpchk GET /healthz
  http-check expect status 200
  mode tcp
  option ssl-hello-chk
  balance roundrobin
    server kmaster1 172.16.16.101:6443 check fall 3 rise 2
    server kmaster2 172.16.16.102:6443 check fall 3 rise 2
    server kmaster3 172.16.16.103:6443 check fall 3 rise 2

EOF
```
##### Enable & restart haproxy service
```
sudo systemctl enable haproxy && sudo systemctl restart haproxy
```
## Pre-requisites on all kubernetes nodes (masters & workers)
##### To begin with, ensure that your system packages are up-to-date;
```
sudo apt update
```
##### Disable swap
```
sudo swapoff -a; sudo sed -i '/swap/d' /etc/fstab
```
##### Disable Firewall
```
sudo systemctl disable --now ufw
```
##### Enable Kernel IP forwarding on Cluster Nodes

To enable IP forwarding, set the value of net.ipv4.ip_forward to 1.
```
echo "net.ipv4.ip_forward=1" | sudo tee -a  /etc/sysctl.conf
```
Apply Achanges
```
sudo sysctl -p
```

##### Load overlay and br_netfilter Kernel Modules on Cluster Nodes

Overlay module provides support for the overlay filesystem. 
`OverlayFS` is type of union filesystem used by container runtimes to layer the container’s root filesystem over the host filesystem.

`br_netfilter module` provides support for packet filtering in Linux bridge networks based on various criteria, such as source and destination IP address, port numbers, and protocol type.

##### Check if these modules are enabled/loaded;
```
lsmod | grep -E "overlay|br_netfilter"
```
##### If not loaded, just load them as follows;
```
{
echo 'overlay br_netfilter' | sudo tee /etc/modules-load.d/kubernetes.conf
sudo modprobe overlay
sudo modprobe br_netfilter
}
```

Similarly, enable Linux kernel’s bridge netfilter to pass bridge traffic to iptables for filtering. 
This means that the packets that are bridged between network interfaces can be filtered using iptables/ip6tables, just as if they were routed packets.
```
{
sudo tee -a /etc/sysctl.conf << 'EOL'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOL
}
```

Apply Changes
```
{
sudo sysctl -p /etc/sysctl.conf
}
```


##### Install containerd runtime on Ubuntu 22.04/Ubuntu 20.04
###### Download & unpack containerd package
```
{
wget https://github.com/containerd/containerd/releases/download/v1.6.14/containerd-1.6.14-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.6.14-linux-amd64.tar.gz
}
```
##### Install runc
##### Runc is a standardized runtime for spawning and running containers on Linux according to the OCI specification
```
{
wget https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
}
```
##### Download and install CNI plugins :
```
{
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
}
```
##### Configure containerd
* Create a containerd directory for the configuration file
* config.toml is the default configuration file for containerd
* Enable systemd group . Use sed command to change the parameter in config.toml instead of using vi editor
* Convert containerd into service
```
{
sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service
}
```
##### Start containerd service & check status
```
{
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl status containerd
}
```

##### Add apt repo for kubernetes
```
{
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -L https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add
sudo touch /etc/apt/sources.list.d/kubernetes.list
sudo chmod 666 /etc/apt/sources.list.d/kubernetes.list
sudo echo deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://apt.kubernetes.io/ kubernetes-xenial main | tee /etc/apt/sources.list.d/kubernetes.list
}
```
##### Install Kubernetes components
###### kubelet,kubectl,kubeadm installation
```
{
  sudo apt update
  apt install -y kubeadm=1.22.0-00 kubelet=1.22.0-00 kubectl=1.22.0-00
}
```

##### Due to a Known Issue When the "kubeadmin init" or "kubeadmin join" commands are run, Ensure to run the below commands:
```
{
echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee --append /etc/sysctl.conf
sudo modprobe br_netfilter
sudo sysctl -p /etc/sysctl.conf

echo "net.ipv4.ip_forward=1" | sudo tee  /etc/sysctl.d/95-IPv4-forwarding.conf
sudo sysctl -p /etc/sysctl.d/95-IPv4-forwarding.conf
}
```

## Bootstrap the cluster

## Only any of the master nodes eg: kmaster1
##### Pre-Pull required images by kubeadmin
```
sudo kubeadm config images pull
```

##### Initialize Kubernetes Cluster
```
sudo kubeadm init --control-plane-endpoint="172.16.16.100:6443" --upload-certs --apiserver-advertise-address=172.16.16.101 --pod-network-cidr=10.100.0.0/16
```
- Note that the `--control-plane-endpoint="172.16.16.100:6443"`= Loadbalancer Virtual IP address.

>**Note**: Copy the respective commands to join other `master nodes` and `worker nodes`, as a result of the previous command.

###### Follow instructions shown as result of the pevious "Kubeadmin init" command. Again, Do the below command, if you want to administer the cluster from this master node.
```
{
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
}
```

##### Deploy Calico network
To deploy a CNI Pod network, `run the below command` on the `master node`;
Install Calico Pod network addon Operator by running the command below. 
Execute the command as the user with which you created the Kubernetes cluster.
```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/master/manifests/tigera-operator.yaml
```

Next, download the custom resources necessary to configure Calico. The `default network` for Calico plugin is `192.168.0.0/16`. 
If you used custom pod CIDR as above (10.100.0.0/16), download the custom resource file and modify the network to match your custom one.
```
wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml
```

* The network section will now look like;
    * -blockSize: 26
    *  cidr: 192.168.0.0/16

##### Update the network subnet to match your subnet.
```
sed -i 's/192.168/10.100/' custom-resources.yaml
```
##### Apply the changes
```
kubectl create -f custom-resources.yaml
```
##### Sample output;
```
    installation.operator.tigera.io/default created
    apiserver.operator.tigera.io/default created
```

## Join other master nodes to the cluster
> Use the respective kubeadm join commands you copied from the output of kubeadm init command on the first master.
You can now join any number of the control-plane node running the following command on each as root:
Eg: Join `Kmaster2`. Run this command on Kmaster2 terminal
```
sudo kubeadm config images pull
```
```
sudo kubeadm join 172.16.16.100:6443 --token 1d7jjq.4fwycym7c9d8xl8f \
        --discovery-token-ca-cert-hash sha256:ab8326e3axxxxxxxxxxxxxxxxxxxx1ec5faeb96062cbd932a8f2fd2 \
        --control-plane --certificate-key 9be525b85dbb34551bxxxxxxxxxxxxxxd6b230c4fbe --apiserver-advertise-address=172.16.16.102
```

>**Warning**: Don't forget the --apiserver-advertise-address option to the join command when you join the other master nodes. And `remember to replace these join commands, with your respectively generated commands`.

>**Note**: Note that the `172.16.16.100:6443` is the Loadbalancer Virtual_IP with port 6443 open, and the `--apiserver-advertise-address=172.16.16.102` is the kmaster2 IP address. This can be any IP of the master node being joined to the cluster. repeat the same process to add more Master nodes.


Eg: Join `Kmaster3`. Run this command on Kmaster3 terminal
```
sudo kubeadm config images pull
```
```
sudo kubeadm join 172.16.16.100:6443 --token 1d7jjq.4fwycym7c9d8xl8f \
        --discovery-token-ca-cert-hash sha256:abxxxxxxx1869b69b1xxxxxxxxxxxxx8b1ec5faeb96062cbd932a8f2fd2 \
        --control-plane --certificate-key 9be525b85dbbxxxxxxxxxxxxxxxxxxxxxxxx9b62eef08db87a6f9d6b230c4fbe --apiserver-advertise-address=172.16.16.103
```
- With kmaster3 IP = 172.16.16.103

Again, Do the below command on each `successfully joined Master Node`, if you want to administer the cluster from that master node.
```
{
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
}
```

## Join worker nodes to the cluster
Eg: Join kworker1. Run this command on kworker1 terminal
```
sudo kubeadm config images pull
```
> Use the kubeadm join command you copied from the output of kubeadm init command on the first master

Then you can `join any number of worker nodes` by running the following on each node as root:
On the respective Worker node terminal
```
sudo kubeadm join 172.16.16.100:6443 --token 1d7jjq.4fwycym7c9d8xl8f \
        --discovery-token-ca-cert-hash sha256:ab8326exxxxxxxxxxxxxxxx8ba733d5ea7678b1ec5faeb96xxxxxd932a8f2fd2
```


## Verifying the cluster
### On any of the master Nodes terminal
```
kubectl cluster-info
kubectl get nodes
```
List pods
```
kubectl get pods --all-namespaces
```
You can list Pods on specific namespaces;
```
kubectl get pods -n calico-system
```
```
kubectl get nodes
```
Role of the `Worker nodes` may show up as `<none>`. This is okay. No role is assigned to the node by default. 
It is only until the control plane assign a workload on the node then it shows up the correct role.

You can however update this ROLE using the command on MASTER-NODE;
```
kubectl label node <worker-node-name> node-role.kubernetes.io/worker=true
```
As you can see, we now have a cluster. Run the command below to get cluster information
```
kubectl cluster-info
```
#or for more debugging info
```
kubectl cluster-info dump
```

>**Note**: If you didn’t save the Kubernetes Cluster joining command, you can at any given time print using the command below on the Master or control plane;
```
sudo kubeadm token create --print-join-command
```

## Configure Cluster Admin Host Machine (Optional)
Configure your admin host for `Cluster remote Access`.

On your Cluster-Admin machine
##### Install kubectl
```
{
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -L https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add
sudo touch /etc/apt/sources.list.d/kubernetes.list
sudo chmod 666 /etc/apt/sources.list.d/kubernetes.list
sudo echo deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://apt.kubernetes.io/ kubernetes-xenial main | tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt install -y kubectl=1.22.0-00
}
```

##### Downloading kube config to your `Cluster Admin Host` machine
On your Cluster Admin host machine
```
mkdir ~/.kube
scp root@172.16.16.101:/etc/kubernetes/admin.conf ~/.kube/config
```
>**Note**: Note that `172.16.16.101` is the IP of the `kmaster1` Node. We are copying config files from there, via SSH.

Password for root account is `kubeadmin` (if you used my Vagrant setup).

##### Verifying the cluster from your  `Cluster Admin Host`.
```
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

Have Fun with K8s!!