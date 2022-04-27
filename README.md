
# Kubernetes (k8s) high availability cluster configuration with kubeadm, Vagrant and VirtualBox
------

## Description


This set of configuration code will enable you to quickly provision a working kubernetes cluster.
The k8s cluster is constructed with kubeadm and utilizes docker containers and calico networking framework.
The idea for the configuration is inspired by the Linux Foundation LFS258 Kubernetes Foundation training.
This configuration has been used to perform all the lab exercises and as such has been tested as fully functional.
The configuration is focused on building high availability cluster control plane with 3 working nodes running cluster of etcd databases.
However the ha-proxy configuration can be omitted to have the base setup for the LFS258 training.
Once the Vagrant boxes are provisioned and the cluster configuration is completed you can start up and halt the cluster using standard Vagrant commands.
You will find explanation to elements of the configuration as comments included in the files.

There are specific Vagrant related elements of the configuration which would not be required for the k8s otherwise. 
Those are related to specific internal Vagrant networking which conflicts with the standard k8s network configuration. 
It is important to be aware of it.

## Getting started

### Dependencies

The configuration has been run and tested on: 

* MacOS 10.12.6

* VirtualBox 6.1.16 (Qt 5.6.3) 

* Vagrant 2.2.19

### Installing

1. Create IP pool for calico networking framework.
```
    vagrant/calico.yaml
```
 
The IP pool for calico needs to be setup before the k8s cluster initialization.  
Assign value to `CALICO_IPV4POOL_CIDR` key.  
The value should match the `--pod-network-cidr` flag in the `kubeadm init` command (set in the provision_script.sh file).  
**Remember** to assign a range which will not overlap your Private Network IP range.  

```    
    - name: CALICO_IPV4POOL_CIDR
      value: "10.1.0.0/16"
```

```
    # The cluster initialization command

    kubeadm init --control-plane-endpoint=k8s-cp \ 
    --apiserver-advertise-address=$IPADDR \ 
    --apiserver-cert-extra-sans=k8s-cp \
    --node-name k8s-cp \
    --pod-network-cidr=10.1.0.0/16 
```

2. Provision first control plane (cp) node.
```
    vagrant up k8s-cp

    vagrant ssh

    vagrant@k8s-cp:~$ kubectl get node
    
    NAME     STATUS   ROLES                  AGE     VERSION
    k8s-cp   Ready    control-plane,master   3m22s   v1.21.1

    vagrant@k8s-cp:~$ ls
    calico.yaml  kubeadm-init.out

    cat kubeadm-init.out

    vagrant up {k8s-cp1,k8s-cp2}

    vagarant ssh k8s-cp
```
3. Generate --certificate key
```    
    sudo kubeadm token create; \
    openssl x509 -pubkey \
    -in /etc/kubernetes/pki/ca.crt | openssl rsa \
    -pubin -outform der 2>/dev/null | openssl dgst \
    -sha256 -hex | sed 's/ˆ.* //'; \

    sudo kubeadm init phase upload-certs --upload-certs; 
     
    # Eg.
    
    vagrant@k8s-cp:~$ sudo kubeadm token create; \
    > openssl x509 -pubkey \
    > -in /etc/kubernetes/pki/ca.crt | openssl rsa \
    > -pubin -outform der 2>/dev/null | openssl dgst \
    > -sha256 -hex | sed 's/ˆ.* //'; \
    > sudo kubeadm init phase upload-certs --upload-certs;

    4dj8qa.swzvfag4gx1ijv7s
    (stdin)= 9171ebb7574bb2ac300af5e780ab5ad68f7dada0f3ab4898ca092e5221a0375a
    I0408 19:23:01.039621    5552 version.go:254] remote version is much newer: v1.23.5; falling back to: stable-1.21
    [upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
    [upload-certs] Using certificate key:
    ccd156a00b27fd2935a2df062e1f764ba94a992c23445877789ea0eed5a60fd4
```     
4. Join nodes to cp cluster.
```    
    vagrant ssh k8s-cp1

    vagrant@k8s-cp1:~$ sudo bash

    root@k8s-cp1:~# kubeadm join k8s-cp:6443 --token 6a2laz.10ja8p26p88awlbd \ 
    --apiserver-advertise-address 192.168.0.41 --discovery-token-ca-cert-hash \ 
    sha256:9171ebb7574bb2ac300af5e780ab5ad68f7dada0f3ab4898ca092e5221a0375a \
    --control-plane --certificate-key ccd156a00b27fd2935a2df062e1f764ba94a992c23445877789ea0eed5a60fd4 
    
    # Check if the node has joined the cp cluster 

    vagrant@k8s-cp:~$ kubectl get node --watch
    NAME      STATUS     ROLES                  AGE   VERSION
    k8s-cp    Ready      control-plane,master   22m   v1.21.1
    k8s-cp1   NotReady   control-plane,master   47s   v1.21.1  
    k8s-cp1   NotReady   control-plane,master   48s   v1.21.1
    k8s-cp1   NotReady   control-plane,master   48s   v1.21.1
    k8s-cp1   Ready      control-plane,master   49s   v1.21.1
    k8s-cp1   Ready      control-plane,master   49s   v1.21.1
    k8s-cp1   Ready      control-plane,master   53s   v1.21.1
    
    # Create $HOME/.kube/config

    vagrant@k8s-cp1:~$ mkdir -p $HOME/.kube

    vagrant@k8s-cp1:~$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    
    vagrant@k8s-cp1:~$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # Verify that cp is operational

    vagrant@k8s-cp1:~$ kubectl get nodes
    
    NAME      STATUS   ROLES                  AGE     VERSION  
    k8s-cp    Ready    control-plane,master   28m     v1.21.1
    k8s-cp1   Ready    control-plane,master   7m16s   v1.21.1
```    
Repeat the joining procedure for the third node (k8s-cp2) 
Remember to update the node IP address --apiserver-advertise-address to the current node IP.    
In this case k8s-cp2 192.168.0.42
```    
    kubeadm join k8s-cp:6443 --token 6a2laz.10ja8p26p88awlbd \
    --apiserver-advertise-address 192.168.0.42 \
    --discovery-token-ca-cert-hash sha256:9171ebb7574bb2ac300af5e780ab5ad68f7dada0f3ab4898ca092e5221a \
    --control-plane --certificate-key ccd156a00b27fd2935a2df062e1f764ba94a992c23445877789ea0eed5a
```
5. Joining worker node to the cluster.
```    
    vagrant up k8s-worker

    vagrant ssh k8s-worker

    sudo kubeadm join k8s-cp:6443 --token 6a2laz.10ja8p26p88awlbd \
        --discovery-token-ca-cert-hash sha256:9171ebb7574bb2ac300af5e780ab5ad68f7dada0f3ab4898ca092e5221a 
    
    # Verify that the node has joined the cluster (it can take couple of seconds).
   
    vagrant@k8s-cp:~$ kubectl get nodes --watch

    NAME         STATUS     ROLES                  AGE    VERSION
    k8s-cp       Ready      control-plane,master   42m    v1.21.1 
    k8s-cp1      Ready      control-plane,master   20m    v1.21.1
    k8s-cp2      Ready      control-plane,master   7m2s   v1.21.1
    k8s-worker   NotReady   <none>                 16s    v1.21.1
    k8s-worker   Ready      <none>                 31s    v1.21.1
    k8s-worker   Ready      <none>                 31s    v1.21.1
    k8s-cp1      Ready      control-plane,master   21m    v1.21.1
    k8s-worker   Ready      <none>                 35s    v1.21.1
```    
6. Setting up ha-proxy.
```
    vagrant up k8s-ha-proxy

    # Redirect cp nodes to ha-proxy service on each node

    sudo vim /etc/hosts

    # Change the IP address of the cp node to the ha-proxy:

    192.168.0.40    k8s-cp

    # to:

    192.168.0.45    k8s-cp 

    # Web browser GUI http://192.168.0.45:9999/stats

    # You should be able to observe the statistics of the traffic to the cp nodes 
    # after permorming cp request eg. kubectl get po -A
```
### Scripts.

In the directory k8s-vagrant/scripts you will find scripts which help to manage taking and removing snapshots. 
I have created those as the k8s cluster experimentations can cause damage to the configurations.
Easiest way is just to rollback to the working state by restoring snapshots.

### Provisioning.

  **Important**

After the initial provisioning deployment the cluster nodes need to be started without provision flag.
Otherwise Vagrant will attempt to re-provision the configuration.
```
    vagrant --no-provision up    
```
Set of commands aliases which will enable you to quickly provision and perform basic Vagrant operations.
```
    # Directory containing the Vagrant file
    alias vdir='cd /vagrant/'

    # Vagrant command
    alias v='vagrant'
    
    # Gracefully shutdown 
    alias vh='vagrant halt'

    # Gracefully shutdown cluster
    alias vha='vh k8s-worker; sleep 1; vh k8s-cp2; sleep 1; vh k8s-cp1; sleep 1; vh k8s-cp; sleep 1; vh k8s-ha-proxy;'
    
    # Show list of the snapshots
    alias vsl='vagrant snapshot list'
    
    # ssh to instance
    alias vssh='vagrant ssh'
    
    # Start the cluster or an instance
    alias vup='vagrant --no-provision up'
```

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Acknowledgments

This project has been inspired by [Liz Rice](https://github.com/lizrice) article: [Kubernetes in Vagrant with kubeadm](https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63).





