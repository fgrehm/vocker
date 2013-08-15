require_relative "errors"

module VagrantPlugins
  module Vocker
    class DockerInstaller
      def initialize(machine)
        @machine = machine
      end

      # This handles verifying the Docker installation, installing it if it was
      # requested, and so on. This method will raise exceptions if things are
      # wrong.
      def ensure_installed
        if !@machine.guest.capability?(:docker_installed)
          @machine.ui.warn(I18n.t("vagrant.docker_cant_detect"))
          return
        end

        if !@machine.guest.capability(:docker_installed)
          @machine.ui.info(I18n.t("vagrant.docker_installing"))
          @machine.guest.capability(:docker_install)

          if !@machine.guest.capability(:docker_installed)
            raise Errors::DockerInstallFailed
          end
        end
      end
    end
  end
end
