# -*- mode: ruby -*-
# vi: set ft=ruby :

## The variables bellow can be overriden in `config.rb` file
$mesos_masters = 3
$mesos_slaves = 1
$memory = 1024*1
$cpus = 2
$network_master = [192, 168, 50]
$network_slaves = [192, 168, 51]

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vbguest.auto_update = false

  vms_masters = (1..$mesos_masters).map{ |a| 'mesos-master-%02d' % [a] }
  ips_masters = {}
  vms_masters.each_with_index{ |i, x| ips_masters[i] = ($network_master + [x+100]).join('.') }
  zk_peers = ips_masters.map{|k,v| "#{v}:2181"}.join(',')


  vms_slaves = (1..$mesos_slaves).map{ |a| 'mesos-slave-%02d' % [a] }
  ips_slaves = {}
  vms_slaves.each_with_index{ |i, x| ips_slaves[i] = ($network_slaves + [x+100]).join('.') }

  ips_all = ips_masters.merge(ips_slaves)

  vms_masters.each_with_index do |i, x|
    config.vm.define vm_name = i do |config|

      config.vm.box_check_update = false
      config.vm.network :private_network, ip: ips_masters[vm_name]

      config.vm.provider :virtualbox do |vb|
        vb.gui = false
        vb.memory = $memory
        vb.cpus = $cpus
      end

      weave_peers = ips_all.select{|host, addr| addr if host != vm_name}.values

      do_provisioning = <<-SCRIPT
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
        sudo echo "deb http://repos.mesosphere.io/ubuntu trusty main" > /etc/apt/sources.list.d/mesosphere.list
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl language-pack-da python-software-properties software-properties-common
        sudo add-apt-repository ppa:webupd8team/java
        sudo apt-get -y update
        sudo apt-get -y install mesos chronos
        sudo curl -sSL https://get.docker.com/gpg | sudo apt-key add -
        sudo curl -sSL https://get.docker.com/ | sh
        sudo echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
        sudo echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
        sudo echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq oracle-java8-installer oracle-java8-set-default > /dev/null
        sudo apt-get -y install marathon
        sudo echo "zk://#{zk_peers}/mesos" > /etc/mesos/zk
        sudo echo #{x+1} > /etc/zookeeper/conf/myid

        string="#{zk_peers}"
        array=(${string//,/ })
        COUNTER=1
        for element in "${array[@]}"
        do
            array2=(${element//:/ })
            src="server.$COUNTER=$array2:2888:3888"

            grep -q "^server.$COUNTER" /etc/zookeeper/conf/zoo.cfg && sed -i "s/^server\.$COUNTER.*/$src/" /etc/zookeeper/conf/zoo.cfg || echo $src >> /etc/zookeeper/conf/zoo.cfg

            COUNTER=$((COUNTER + 1))
        done

        sudo echo 2 > /etc/mesos-master/quorum
        sudo echo 'Mesos Cluster Vagrant' > /etc/mesos-master/cluster
        sudo echo #{ips_masters[vm_name]} > /etc/mesos-master/ip
        sudo cp /etc/mesos-master/ip /etc/mesos-master/hostname

        sudo mkdir -p /etc/marathon/conf
        sudo cp /etc/mesos-master/hostname /etc/marathon/conf
        sudo cp /etc/mesos/zk /etc/marathon/conf/master

        sudo echo "zk://#{zk_peers}/marathon" > /etc/marathon/conf/zk

        #sudo curl -L git.io/weave -o /usr/local/bin/weave
        #sudo chmod a+x /usr/local/bin/weave
        #sudo eval $(weave env)
        #sudo weave stop
        #sudo weave launch #{weave_peers.join(' ')}

        sudo service mesos-slave stop
        sudo service zookeeper restart
        sudo service mesos-master restart
        sudo service marathon restart
        sudo echo manual > /etc/init/mesos-slave.override

      SCRIPT

      config.vm.provision :shell, inline: do_provisioning
    end
  end


  vms_slaves.each_with_index do |i, x|
    config.vm.define vm_name = i do |config|

      config.vm.box_check_update = false
      config.vm.network :private_network, ip: ips_slaves[vm_name]

      config.vm.provider :virtualbox do |vb|
        vb.gui = false
        vb.memory = $memory
        vb.cpus = $cpus
      end

      weave_peers = ips_all.select{|host, addr| addr if host != vm_name}.values

      do_provisioning = <<-SCRIPT
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
        sudo echo "deb http://repos.mesosphere.io/ubuntu trusty main" > /etc/apt/sources.list.d/mesosphere.list
        sudo apt-get -y update
        sudo apt-get -y install curl mesos language-pack-da
        sudo curl -sSL https://get.docker.com/gpg | sudo apt-key add -
        sudo curl -sSL https://get.docker.com/ | sh
        sudo echo "zk://#{zk_peers}/mesos" > /etc/mesos/zk

        sudo echo #{ips_slaves[vm_name]} > /etc/mesos-slave/ip
        sudo cp /etc/mesos-slave/ip /etc/mesos-slave/hostname

        sudo echo 'docker,mesos' > /etc/mesos-slave/containerizers
        sudo echo '5mins' > /etc/mesos-slave/executor_registration_timeout

        #sudo curl -L git.io/weave -o /usr/local/bin/weave
        #sudo chmod a+x /usr/local/bin/weave
        #sudo eval $(weave env)
        #sudo weave stop
        #sudo weave launch #{weave_peers.join(' ')}

        sudo service zookeeper stop
        sudo service mesos-master stop
        sudo echo manual > /etc/init/zookeeper.override
        sudo echo manual > /etc/init/mesos-master.override
        sudo service mesos-slave restart

      SCRIPT

      config.vm.provision :shell, inline: do_provisioning
    end
  end

end
