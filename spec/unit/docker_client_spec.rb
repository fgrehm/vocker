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

    context 'parameters' do
      let(:containers) { {
        'my-db' => {
          image:               'mysql',
          cidfile:             '/foo/bla',
          dns:                 '127.0.0.1',
          volumes:             ['/host/path:/guest/path', '/container-volume'],
          ports:               ['1:2', ':3'],
          additional_run_args: 'some parameter'
        }
      } }

      before do
        stub(communicator).test(with{|cmd| cmd =~ /docker ps/}) { false }
        subject.run containers
      end

      it 'automatically assigns a digest of the image name as the cidfile if not specified' do
        stub(Digest::SHA1).hexdigest('my-db') { 'digest' }
        containers['my-db'][:cidfile] = nil
        subject.run containers
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /-cidfile=\/var\/lib\/vocker\/cids\/digest/})
      end

      it 'allows cidfile to be specified' do
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /-cidfile=\/foo\/bla/})
      end

      it 'allows a dns to be specified' do
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /-dns=127\.0\.0\.1/})
      end

      it 'allows an array of ports to be specified' do
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /-p 1:2 -p :3/})
      end

      it 'allows an array of volumes to be specified' do
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /-v \/host\/path:\/guest\/path -v \/container-volume/})
      end

      it 'provides the container name to the docker command' do
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /-name=my-db/})
      end

      it 'allows additional params to be passed to the run command' do
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /some parameter/})
      end
    end

    context 'when the container already exists' do
      before do
        stub(communicator).test(with{|cmd| cmd =~ /docker ps -a -q/}) { true }
      end

      it 'starts the container if it is stopped' do
        stub(communicator).test(with{|cmd| cmd =~ /docker ps -q/}) { false }
        subject.run containers
        expect(communicator).to have_received.sudo(with{|cmd| cmd =~ /docker start/})
      end

      it 'noops if container is already running' do
        stub(communicator).test(with{|cmd| cmd =~ /docker ps -q/}) { true }
        subject.run containers
        expect(communicator).to_not have_received.sudo(with{|cmd| cmd =~ /docker start/})
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
