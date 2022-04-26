# k8s kubeadm cluster config Vagrnatfile
# tested with VB Version 6.1.16 r140961 (Qt5.6.3)

Vagrant.configure("2") do |config|

    # ha-proxy node
    config.vm.define "k8s-ha-proxy" do |haproxy|
        haproxy.vm.box = "ubuntu/bionic64"
        haproxy.vm.hostname = "k8s-ha-proxy"   
        haproxy.vm.network "public_network", bridge: "en0: Broadcom NetLink Gigabit Ethernet Controller", ip: "192.168.0.45" 
        haproxy.vm.provider "virtualbox" do |vb|    
            vb.memory = 2048
            vb.cpus = 1
        end
    end
    
    # master (cp) node
    config.vm.define "k8s-cp" do |cp|
        cp.vm.box = "ubuntu/bionic64"
        cp.vm.hostname = "k8s-cp"
        cp.vm.network "public_network", bridge: "en0: Broadcom NetLink Gigabit Ethernet Controller", ip: "192.168.0.40"
        cp.vm.provider "virtualbox" do |vb|    
            vb.memory = 4096
            vb.cpus = 8
        end
    end

    config.vm.define "k8s-cp1" do |cp|
        cp.vm.box = "ubuntu/bionic64"
        cp.vm.hostname = "k8s-cp1"
        cp.vm.network "public_network", bridge: "en0: Broadcom NetLink Gigabit Ethernet Controller", ip: "192.168.0.41"
        cp.vm.provider "virtualbox" do |vb|    
            vb.memory = 4096
            vb.cpus = 4
        end
    end

    config.vm.define "k8s-cp2" do |cp|
        cp.vm.box = "ubuntu/bionic64"
        cp.vm.hostname = "k8s-cp2"
        cp.vm.network "public_network", bridge: "en0: Broadcom NetLink Gigabit Ethernet Controller", ip: "192.168.0.42"
        cp.vm.provider "virtualbox" do |vb|    
            vb.memory = 4096
            vb.cpus = 4
        end
    end

    # worker node
    config.vm.define "k8s-worker" do |worker|
        worker.vm.box = "ubuntu/bionic64"
        worker.vm.hostname = "k8s-worker"
        worker.vm.network "public_network", bridge: "en0: Broadcom NetLink Gigabit Ethernet Controller", ip: "192.168.0.50"
        worker.vm.provider "virtualbox" do |vb|    
            vb.memory = 2048
            vb.cpus = 4
        end
    end

    # provision script
    config.vm.provision "shell", path: "provision_script.sh"
    # config.vm.synced_folder ".", "/folder"  
    config.vm.synced_folder "./vagrant", "/vagrant"
  
end