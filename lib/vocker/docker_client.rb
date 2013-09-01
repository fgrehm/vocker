require 'digest/sha1'

module VagrantPlugins
  module Vocker
    class DockerClient
      def initialize(machine)
        @machine = machine
      end

      def pull_images(*images)
        @machine.communicate.tap do |comm|
          images.each do |image|
            comm.sudo("docker images | grep -q #{image} || docker pull #{image}")
          end
        end
      end

      def daemon_running?
        @machine.communicate.test('test -f /var/run/docker.pid')
      end

      def run(containers)
        containers.each do |name, config|
          cids_dir = "/var/lib/vocker/cids"
          config[:cidfile] ||= "#{cids_dir}/#{Digest::SHA1.hexdigest name}"

          @machine.communicate.sudo("mkdir -p #{cids_dir}")
          run_container(config)
        end
      end

      def run_container(config)
        id = "$(cat #{config[:cidfile]})"

        if container_exist?(id)
          start_container(id)
        else
          create_container(config)
        end
      end

      def container_exist?(id)
        @machine.communicate.test("sudo docker ps -a -q | grep -q #{id}")
      end

      def start_container(id)
        @machine.communicate.sudo("docker start #{id}")
      end

      def create_container(config)
        @machine.communicate.sudo %[
          rm -f #{config[:cidfile]}
          docker run -cidfile=#{config[:cidfile]} -d #{config[:image]} #{config[:cmd]}
        ]
      end
    end
  end
end
