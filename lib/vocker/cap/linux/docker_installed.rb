module VagrantPlugins
  module Vocker
    module Cap
      module Linux
        module DockerInstalled
          def self.docker_installed(machine)
            machine.communicate.test("test -d /var/lib/docker", sudo: true)
          end
        end
      end
    end
  end
end
