#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Get the NODENAME that VirtualBox has given this VM
NODENAME=$(hostname -s)

# IPs of control plane and ha-proxy 
K8S_CP_IP="192.168.0.40"

install_k8s (){
    # Install kubernetes & other packages
    apt-get update && apt-get upgrade -y
    apt-get install -y apt-transport-https
    apt-get install -y docker.io
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - 
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubeadm=1.21.1-00 kubelet=1.21.1-00 kubectl=1.21.1-00
    apt-get install -y jq
    apt-mark hold kubelet kubeadm kubectl

    # kubelet requires swap off
    swapoff -a

    # keep swap off after reboot
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    # auto-completion
    echo "source <(kubectl completion bash)" >> ~/.bashrc 
}

# Set up ha-proxy control plane node
if [ $NODENAME = "k8s-ha-proxy" ]
    then
    #install haproxy
    sudo apt-get update ; sudo apt-get install -y haproxy vim
    sudo cp -v /vagrant/haproxy.cfg /etc/haproxy/haproxy.cfg
    sudo systemctl restart haproxy.service
fi

# Set up Kubernetes control plane node
if [ $NODENAME = "k8s-cp" ]
    then
    install_k8s
    IPADDR=`ifconfig enp0s8 | grep -w inet | awk '{print $2}';`

    # Single control version 
    echo "${K8S_CP_IP}    k8s-cp" >> /etc/hosts

    cat /etc/hosts

    # Initialize custer

    kubeadm init --control-plane-endpoint=k8s-cp --apiserver-advertise-address=$IPADDR --apiserver-cert-extra-sans=k8s-cp --node-name k8s-cp --pod-network-cidr=10.1.0.0/16 | tee kubeadm-init.out
    
    # Set up admin creds for the vagrant user

    sudo --user=vagrant mkdir -p /home/vagrant/.kube && echo "mkdir -p /home/vagrant/.kube - DONE" || echo "mkdir -p /home/vagrant/.kube - FAIL"

    cp -iv /etc/kubernetes/admin.conf /home/vagrant/.kube/config && echo "cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config - DONE" || echo "cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config - FAIL"

    chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config && echo "chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config - DONE " || echo "chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config - FAIL"

    cp -v /vagrant/calico.yaml /home/vagrant/ && echo "cp /vagrant/calico.yaml /home/vagrant/ - DONE" || echo "cp /vagrant/calico.yaml /home/vagrant/ - FAIL"
    
    su - vagrant -c "kubectl apply -f calico.yaml" && echo "sudo --user=vagrant kubectl apply -f calico.yaml - DONE" || echo "sudo --user=vagrant kubectl apply -f calico.yaml - FAIL"

    # fix the vagrant interface en0 IP issue
    echo "KUBELET_EXTRA_ARGS=--node-ip=${IPADDR}" > /etc/default/kubelet
    systemctl restart kubelet.service 

fi

for i in {1..2};do
    if [ $NODENAME == "k8s-cp$i" ]
        then
        IPADDR=`ifconfig enp0s8 | grep -w inet | awk '{print $2}';`
        install_k8s
        
        # For the cluster initialisation stage Cluster IP 
        echo "${K8S_CP_IP}    k8s-cp" >> /etc/hosts
        
        cat /etc/hosts    

        # fix the vagrant interface en0 IP issue
        echo "KUBELET_EXTRA_ARGS=--node-ip=${IPADDR}" > /etc/default/kubelet
        systemctl restart kubelet.service
 
    fi
done

if [ $NODENAME = "k8s-worker" ]
    then
    install_k8s
    # For the cluster initialisation stage Cluster IP 
    echo "${K8S_CP_IP}    k8s-cp" >> /etc/hosts
    
    cat /etc/hosts

    # fix the vagrant interface en0 IP issue
    echo "KUBELET_EXTRA_ARGS=--node-ip=${IPADDR}" > /etc/default/kubelet
    systemctl restart kubelet.service 
fi
exit 0