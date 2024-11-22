NUM_WORKER_NODES=2
K8S_IP_NW="192.168.10."
M_IP_START=10
W_IP_START=20

Vagrant.configure("2") do |config|
	
    config.vm.define "k8scpmt" do |k8scpm01|
      k8scpm01.vm.box = "ubuntu/jammy64"
      k8scpm01.vm.hostname = 'k8scpmaster01'
      
	  # Configure networks.
      # k8scpm01.vm.network "private_network", ip: "192.168.10.10", auto_config: true
	  k8scpm01.vm.network "private_network", ip: K8S_IP_NW + "#{M_IP_START}"

      # Provisioning: Install k8smaster node
      k8scpm01.vm.provision "shell", inline: <<-SHELL
	     NODE_IP=$(ip -o -4 addr show | grep "#{K8S_IP_NW}" | awk '{print $4}' | awk -F/ '{print $1}')
		 sudo sed -i -E "s|^KUBELET_EXTRA_ARGS=.*|KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}|" /etc/default/kubelet
      SHELL
    end
 
    config.vm.define "k8wk1" do |k8wk01|
      k8wk01.vm.box = "ubuntu/jammy64"
      k8wk01.vm.hostname = 'k8worker01'  
      
	  # Configure networks
      # k8wk01.vm.network "private_network", ip: "192.168.10.20", auto_config: true
	  k8wk01.vm.network "private_network", ip: K8S_IP_NW + "#{W_IP_START}"
      # # Provisioning: Install k8worker node
      k8wk01.vm.provision "shell", inline: <<-SHELL
		 NODE_IP=$(ip -o -4 addr show | grep "#{K8S_IP_NW}" | awk '{print $4}' | awk -F/ '{print $1}')
		 sudo sed -i -E "s|^KUBELET_EXTRA_ARGS=.*|KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}|" /etc/default/kubelet
      SHELL
    end
	
	config.vm.define "k8wk2" do |k8wk02|
      k8wk02.vm.box = "ubuntu/jammy64"
      k8wk02.vm.hostname = 'k8worker02'
  
      # Configure networks
      k8wk02.vm.network "private_network", ip: "192.168.10.21", auto_config: true
	  
      # Provisioning: Install k8worker node
      k8wk02.vm.provision "shell", inline: <<-SHELL
		 NODE_IP=$(ip -o -4 addr show | grep "#{K8S_IP_NW}" | awk '{print $4}' | awk -F/ '{print $1}')
		 sudo sed -i -E "s|^KUBELET_EXTRA_ARGS=.*|KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}|" /etc/default/kubelet
	  SHELL
    end
	
	config.vm.provider "virtualbox" do |v|
        v.memory = 3096
        v.cpus = 4
        v.customize ["modifyvm", :id, "--boot4", "disk", "--audio-enabled=off", "--nic-type1", "82543GC", "--nicpromisc1", "deny", "--nic-type2", "Am79C970A", "--nicpromisc2", "allow-all", "--nic-type3", "Am79C970A", "--nicpromisc3", "allow-vms"]
	end

	config.vm.provision "file", source: "kubernets_manage.sh", destination: "/tmp/kubernets_manage.sh"
	config.vm.provision "shell", inline: <<-SHELL
		  sudo echo  "192.168.10.10 k8scpmaster01 master01" >> /etc/hosts
		  
	      echo "$K8S_IP_NW$((M_IP_START)) k8worker-node$(W_IP_START)" >> /etc/hosts
		  echo "$K8S_IP_NW$((M_IP_START++)) k8worker-node$(W_IP_START++)" >> /etc/hosts
		  
	      
		  sudo echo  "192.168.10.20 k8worker01 worker01" >> /etc/hosts
		  sudo echo  "192.168.10.21 k8worker02 worker02" >> /etc/hosts
		  sudo apt-get update
          sudo apt-get install dos2unix net-tools
          sudo dos2unix /tmp/kubernets_manage.sh
		  bash -x /tmp/kubernets_manage.sh
    SHELL
end