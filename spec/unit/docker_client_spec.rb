require 'spec_helper'

require Vagrant.source_root.join('plugins/communicators/ssh/communicator')

require 'vocker/docker_client'

describe VagrantPlugins::Vocker::DockerClient do
  verify_contract(:docker_client)

  fake(:communicator, test: true) { VagrantPlugins::CommunicatorSSH::Communicator }

  let(:machine) { fake(:machine, communicate: communicator) }

  subject { described_class.new(machine) }

  it 'pulls configured images' do
    subject.pull_images 'base', 'mysql'
    expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /docker pull base/})
    expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /docker pull mysql/})
  end

  it 'verifies if the docker daemon is running' do
    stub(communicator).test(with{|cmd| cmd == 'test -f /var/run/docker.pid'}) { true }
    expect(subject.daemon_running?).to be_true

    stub(communicator).test(any_args) { false }
    expect(subject.daemon_running?).to be_false
  end

  context 'running containers' do
    let(:containers) { {'mysql' => {image: 'mysql'}} }

    it 'ensures container ids folder exists' do
      subject.run containers
      expect(communicator).to have_received.sudo('mkdir -p /var/lib/vocker/cids')
    end

    it 'automatically assigns a digest of the command as the cidfile if not specified' do
      stub(communicator).test(with{|cmd| cmd =~ /docker ps/}) { false }
      stub(Digest::SHA1).hexdigest('mysql') { 'digest' }
      subject.run containers
      expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /-cidfile=\/var\/lib\/vocker\/cids\/digest/})
    end

    it 'allows cidfile to be specified' do
      stub(communicator).test(with{|cmd| cmd =~ /docker ps/}) { false }
      containers['mysql'][:cidfile] = '/foo/bla'
      subject.run containers
      expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /-cidfile=\/foo\/bla/})
    end

    context 'when the container already exists' do
      before do
        stub(communicator).test(with{|cmd| cmd =~ /docker ps/}) { true }
        subject.run containers
      end

      it 'starts the container' do
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /docker start/})
      end
    end

    context 'when the container does not exist' do
      before do
        stub(communicator).test(with{|cmd| cmd =~ /docker ps/}) { false }
        subject.run containers
      end

      it 'creates a new container' do
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /docker run/})
      end
    end
  end
end
