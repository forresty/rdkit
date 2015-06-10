VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.define 'redis' do |c|
    config.vm.provision "shell", inline: "sudo apt-get install redis-tools -y"

    c.vm.provision "docker" do |docker|
      docker.run "redis", args: "-p 6379:6379"
    end
  end
end
