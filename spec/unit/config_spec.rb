require 'spec_helper'

require 'vocker/config'

describe VagrantPlugins::Vocker::Config do
  verify_contract(:config)

  it 'combines images when merging' do
    config = described_class.new.tap{|c| c.pull_images 'ubuntu', 'basebox' }
    other  = described_class.new.tap{|c| c.pull_images 'basebox', 'centos' }
    merged = config.merge(other)

    expect(merged.images.to_a).to match_array(['basebox', 'centos', 'ubuntu'])
  end

  it 'merges containers definitions' do
    config = described_class.new.tap{|c| c.run 'ls', cmd: 'ls', image: 'ubuntu' }
    other  = described_class.new.tap{|c| c.run 'ls', cmd: 'ls -la', image: 'ubuntu' }
    merged = config.merge(other)

    expect(merged.containers).to include({'ls' => {cmd: 'ls -la', image: 'ubuntu'}})
  end

  describe 'containers arguments normalization' do
    it 'maps a single argument as the image name' do
      config = described_class.new.tap{|c| c.run 'mysql' }
      expect(config.containers).to include('mysql' => {image: 'mysql'})
    end

    context 'when two strings are provided' do
      subject { described_class.new.tap{|c| c.run 'ls -la', 'ubuntu' } }

      it 'maps the first argument as the command' do
        expect(subject.containers.values.first).to include(cmd: 'ls -la')
      end

      it 'maps the second argument as the image name' do
        expect(subject.containers.values.first).to include(image: 'ubuntu')
      end
    end
  end
end
