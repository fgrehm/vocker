require "vagrant"

I18n.load_path << File.expand_path(File.dirname(__FILE__) + '/../../locales/en.yml')
I18n.reload!

module VagrantPlugins
  module Vocker
    class Plugin < Vagrant.plugin("2")
      name "Vocker"
      description <<-DESC
      Introduces Docker to Vagrant
      DESC

      config(:docker, :provisioner) do
        require_relative "config"
        Config
      end

      guest_capability("debian", "docker_install") do
        require_relative "cap/debian/docker_install"
        Cap::Debian::DockerInstall
      end

      guest_capability("linux", "docker_installed") do
        require_relative "cap/linux/docker_installed"
        Cap::Linux::DockerInstalled
      end

      provisioner(:docker) do
        require_relative "provisioner"
        Provisioner
      end

      command(:docker) do
        require_relative "command"
        Command
      end
    end
  end
end
