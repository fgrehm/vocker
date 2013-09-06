module VagrantPlugins
  module Vocker
    module Cap
      module Debian
        module DockerConfigureAutoStart
          def self.docker_configure_auto_start(machine)
            machine.communicate.sudo("sed -i.bak 's/docker -d/docker -d -r=true/' /etc/init/docker.conf ")
          end
        end
      end
    end
  end
end
