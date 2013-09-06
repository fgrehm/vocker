require 'spec_helper'

require 'vagrant/ui'
require Vagrant.source_root.join('plugins/communicators/ssh/communicator')

require 'vocker/docker_installer'

describe VagrantPlugins::Vocker::DockerInstaller do
  verify_contract(:docker_installer)

  fake(:guest)
  fake(:ui) { Vagrant::UI::Interface }
  let(:machine) { fake(:machine, guest: guest, ui: ui) }

  subject { described_class.new(machine) }

  it 'skips docker installation if guest is not capable' do
    stub(guest).capability?(:docker_installed) { false }

    subject.ensure_installed

    expect(guest).to_not have_received.capability(:docker_installed)
    expect(guest).to_not have_received.capability(:docker_install)
  end

  it 'skips docker installation if already installed' do
    stub(guest).capability(:docker_installed) { true }

    subject.ensure_installed

    expect(guest).to have_received.capability(:docker_installed)
    expect(guest).to_not have_received.capability(:docker_install)
  end

  it 'installs docker if not installed' do
    # XXX: This is kinda hacky I believe
    stub(guest).capability(:docker_installed) {
      stub(guest).capability(:docker_installed) { true }
      false
    }

    subject.ensure_installed

    expect(guest).to have_received.capability(:docker_installed)
    expect(guest).to have_received.capability(:docker_install)
    expect(guest).to have_received.capability(:docker_configure_auto_start)
  end

  it 'errors out if docker could not be installed' do
    stub(guest).capability(:docker_installed) { false }

    expect {
      subject.ensure_installed
    }.to raise_error(VagrantPlugins::Vocker::Errors::DockerInstallFailed)
  end
end
