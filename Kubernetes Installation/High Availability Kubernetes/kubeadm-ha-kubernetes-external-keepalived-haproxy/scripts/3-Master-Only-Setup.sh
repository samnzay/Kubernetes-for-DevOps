#!/bin/bash

#Bootstrap the cluster
######################

#On any of the master nodes eg: kmaster1
#Pull required images by kubeadmin
sudo kubeadm config images pull

#Initialize Kubernetes Cluster
sudo kubeadm init --control-plane-endpoint="172.16.16.100:6443" --upload-certs --apiserver-advertise-address=172.16.16.101 --pod-network-cidr=10.100.0.0/16
#Copy the resulted commands to join other "master nodes" and "worker nodes".

#Follow instruction shown as result of "Kubeadmin init" command
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#To deploy a CNI Pod network, run the command below on the master node;
#Install Calico Pod network addon Operator by running the command below. 
#Execute the command as the user with which you created the Kubernetes cluster.

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/master/manifests/tigera-operator.yaml

#Next, download the custom resources necessary to configure Calico. The default network for Calico plugin is 192.168.0.0/16. 
#If you used custom pod CIDR as above (10.100.0.0/16), download the custom resource file and modify the network to match your custom one.
wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml

#The network section will now look like;
    #- blockSize: 26
    #  cidr: 192.168.0.0/16

#Update the network subnet to match your subnet.
sed -i 's/192.168/10.100/' custom-resources.yaml

#Apply the changes
kubectl create -f custom-resources.yaml

#Sample output;
    #installation.operator.tigera.io/default created
    #apiserver.operator.tigera.io/default created
