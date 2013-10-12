module VagrantPlugins
  module Vocker
    module Cap
      module Debian
        module DockerConfigureVagrantUser
          def self.docker_configure_vagrant_user(machine)
            # FIXME: We should make use of the config.ssh.username here
            machine.communicate.sudo("usermod -a -G docker vagrant")
          end
        end
      end
    end
  end
end
