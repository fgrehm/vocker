require 'spec_helper'

require 'vagrant/ui'

require 'vocker/config'
require 'vocker/provisioner'

describe VagrantPlugins::Vocker::Provisioner do
  verify_contract(:provisioner)

  fake(:guest)
  fake(:ui) { Vagrant::UI::Interface }

  let(:installer) { fake(:docker_installer, ensure_installed: nil) }
  let(:client)    { fake(:docker_client, daemon_running?: true) }
  let(:config)    { VagrantPlugins::Vocker::Config.new }
  let(:machine)   { fake(:machine, guest: guest, ui: ui) }

  subject { described_class.new(machine, config, installer, client) }

  before do
    config.pull_images 'base', 'mysql'
    config.run 'mysql'
  end

  context 'docker can be installed and daemon is running' do
    before { subject.provision }

    it 'ensures docker gets installed' do
      expect(installer).to have_received.ensure_installed
    end

    it 'pulls configured images' do
      expect(client).to have_received.pull_images(*config.images)
    end

    it 'runs configured containers' do
      expect(client).to have_received.run(with{|c| c['mysql'][:image] == 'mysql'})
    end
  end

  context 'docker daemon is not able to start' do
    before { stub(client).daemon_running? { false } }

    it 'raises an error' do
      expect{
        subject.provision
      }.to raise_error(VagrantPlugins::Vocker::Errors::DockerNotRunning)
    end
  end
end
