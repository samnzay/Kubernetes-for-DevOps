#On any of the master Nodes terminal

#Verify The Cluster
#==================
kubectl get pods --all-namespaces
#You can list Pods on specific namespaces;
kubectl get pods -n calico-system

kubectl get nodes
#Role of the Worker nodes may show up as <none>. This is okay. No role is assigned to the node by default. 
#It is only until the control plane assign a workload on the node then it shows up the correct role.

#You can however update this ROLE using the command on MASTER-NODE;
kubectl label node <worker-node-name> node-role.kubernetes.io/worker=true
#As you can see, we now have a cluster. Run the command below to get cluster information
kubectl cluster-info
#or for more debugging info
kubectl cluster-info dump

#If you didn’t save the Kubernetes Cluster joining command,
#you can at any given time print using the command below on the Master or control plane;
sudo kubeadm token create --print-join-command
