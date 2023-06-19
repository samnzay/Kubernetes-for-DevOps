#On your Cluster-Admin machine

# kubectl installation
######################
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -L https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add
sudo touch /etc/apt/sources.list.d/kubernetes.list
sudo chmod 666 /etc/apt/sources.list.d/kubernetes.list
sudo echo deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://apt.kubernetes.io/ kubernetes-xenial main | tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt install -y kubectl=1.22.0-00

#Downloading kube config to your local machine
#On your Cluster-Admin machine
mkdir ~/.kube
scp root@172.16.16.101:/etc/kubernetes/admin.conf ~/.kube/config
#Password for root account is "kubeadmin" (if you used my Vagrant setup)

#Verifying the cluster
kubectl cluster-info
kubectl get nodes

kubectl get pods --all-namespaces