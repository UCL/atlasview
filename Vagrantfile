Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04-arm64"
  config.vm.hostname = "vagrant"

  config.vm.provider "vmware_fusion" do |v|
	v.vmx["memsize"] = "4096"
	v.vmx["numvcpus"] = "2"
  end

  config.vm.provision "ansible" do |ansible|
	ansible.verbose = "v"
	ansible.playbook = "provisioning/playbook.yml"
  end
end
