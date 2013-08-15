module VagrantPlugins
  module Vocker
    class Command < Vagrant.plugin("2", :command)
      DOCKER_COMMANDS = %w(
        attach build commit diff events export history images import info
        insert inspect kill login logs port top ps pull push restart rm
        rmi run search start stop tag version wait
      )
      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant docker [vm-name] COMMAND [ARGS]"
          o.separator ""
          o.separator "COMMAND can be any of #{DOCKER_COMMANDS.join(', ')}"
          o.separator ""
        end

        # Parse out docker commands
        options = {}
        command_index = @argv.index{|cmd| DOCKER_COMMANDS.include? cmd}
        if command_index
          options[:command] = @argv.drop(command_index)
          @argv             = @argv.take(command_index)
        end

        # Parse the options and return if we don't have any target.
        argv = parse_options(opts)
        return if !argv

        # Execute the actual Docker command
        # TODO: Make it work with multiple VMs
        with_target_vms(argv, :single_target => true) do |vm|
          # FIXME: - Check if docker is running first
          #        - Handle empty command

          @logger.debug("Executing docker command on remote machine: #{options[:command]}")
          env = vm.action(:ssh_run, :ssh_run_command => "sudo docker #{options[:command].join(' ')}")

          # Exit with the exit status of the command or a 0 if we didn't
          # get one.
          exit_status = env[:ssh_run_exit_status] || 0
          return exit_status
        end
      end
    end
  end
end
