
#Then you can join any number of worker nodes by running the following on each as root:
#On the Worker node terminal
sudo kubeadm join 172.16.16.100:6443 --token 1d7jjq.4fwycym7c9d8xl8f \
        --discovery-token-ca-cert-hash sha256:ab8326e3a1869b69b1a8bb88ba733d5ea7678b1ec5faeb96062cbd932a8f2fd2
