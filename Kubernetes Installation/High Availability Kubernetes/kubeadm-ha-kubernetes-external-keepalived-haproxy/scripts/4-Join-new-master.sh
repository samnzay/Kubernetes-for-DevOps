
#You can now join any number of the control-plane node running the following command on each as root:
#Eg: Join Kmaster2. Run this command on Kmaster2 termainal
sudo kubeadm config images pull

sudo kubeadm join 172.16.16.100:6443 --token 1d7jjq.4fwycym7c9d8xl8f \
        --discovery-token-ca-cert-hash sha256:ab8326e3a1869b69b1a8bb88ba733d5ea7678b1ec5faeb96062cbd932a8f2fd2 \
        --control-plane --certificate-key 9be525b85dbb34551b5841075475aebcbde29b62eef08db87a6f9d6b230c4fbe --apiserver-advertise-address=172.16.16.102


#Eg: Join Kmaster3. Run this command on Kmaster3 terminal
sudo kubeadm config images pull

sudo kubeadm join 172.16.16.100:6443 --token 1d7jjq.4fwycym7c9d8xl8f \
        --discovery-token-ca-cert-hash sha256:ab8326e3a1869b69b1a8bb88ba733d5ea7678b1ec5faeb96062cbd932a8f2fd2 \
        --control-plane --certificate-key 9be525b85dbb34551b5841075475aebcbde29b62eef08db87a6f9d6b230c4fbe --apiserver-advertise-address=172.16.16.103
