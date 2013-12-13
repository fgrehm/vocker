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

      def start_service
        if !daemon_running? && @machine.guest.capability?(:docker_start_service)
          @machine.guest.capability(:docker_start_service)
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
          run_container({name: name}.merge config)
        end
      end

      def run_container(config)
        raise "Container's cidfile was not provided!" unless config[:cidfile]

        id = "$(cat #{config[:cidfile]})"

        if container_exist?(id)
          start_container(id)
        else
          create_container(config)
        end
      end

      def container_exist?(id)
        lookup_container(id, true)
      end

      def start_container(id)
        unless container_running?(id)
          @machine.communicate.sudo("docker start #{id}")
        end
      end

      def container_running?(id)
        lookup_container(id)
      end

      def create_container(config)
        # DISCUSS: Does this really belong here?
        ensure_bind_mounts_exist(config)

        args = "-cidfile=#{config[:cidfile]} -d "
        args << prepare_run_arguments(config)
        @machine.communicate.sudo %[
          rm -f #{config[:cidfile]}
          docker run #{args} #{config[:image]} #{config[:cmd]}
        ]
      end

      private

      def ensure_bind_mounts_exist(config)
        Array(config[:volumes]).each do |volume|
          if volume =~ /(.+):.+/
            guest_vm_path = $1
            @machine.communicate.sudo "mkdir -p #{guest_vm_path}"
          end
        end
      end

      def prepare_run_arguments(config)
        args = []

        args << "-dns=#{config[:dns]}"            if config[:dns]
        args << "-name=#{config[:name]}"          if config[:name]
        args << "#{config[:additional_run_args]}" if config[:additional_run_args]

        args += Array(config[:volumes]).map { |volume| "-v #{volume}" }
        args += Array(config[:ports]).map   { |port| "-p #{port}" }
        args += Array(config[:links]).map   { |link| "-link #{link}" }

        args.compact.flatten.join ' '
      end

      def lookup_container(id, list_all = false)
        docker_ps = "sudo docker ps -q"
        docker_ps << " -a" if list_all
        @machine.communicate.tap do |comm|
          # Docker < 0.7.0 stores container IDs using its short version while
          # recent versions use the full container ID
          # See https://github.com/dotcloud/docker/pull/2140 for more information
          return comm.test("#{docker_ps} | grep -wFq #{id}") ||
                   comm.test("#{docker_ps} -notrunc | grep -wFq #{id}")
        end
      end
    end
  end
end
