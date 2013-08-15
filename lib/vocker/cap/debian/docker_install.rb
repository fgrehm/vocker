module VagrantPlugins
  module Vocker
    module Cap
      module Debian
        module DockerInstall
          def self.docker_install(machine)
            # Inspired on https://github.com/progrium/dokku/blob/master/Makefile#L33-L40
            machine.communicate.tap do |comm|
              # TODO: Try to not depend on installing software-properties-common
              comm.sudo("apt-get install -y -q software-properties-common")
              comm.sudo("apt-add-repository -y ppa:dotcloud/lxc-docker")
              comm.sudo("apt-get update")
              comm.sudo("apt-get install -y -q xz-utils lxc-docker -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'")
              # TODO: Error out if provider is lxc
              # comm.sudo("lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`")
            end
          end
        end
      end
    end
  end
end
