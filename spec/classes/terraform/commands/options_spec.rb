require 'spec_helper'

RSpec.describe Terradactyl::Terraform::Commands::Options do

  after(:each) do
    subject.reset!
  end

  context 'simple initialization' do
    describe '#binary' do
      context 'VersionManager has installed binaries' do
        before do
          @version = '0.11.14'
          Terradactyl::Terraform::VersionManager.install(@version)
        end

        after do
          Terradactyl::Terraform::VersionManager.remove(@version)
        end

        it 'returns VersionManager binary path' do
          expect(subject.binary).to match(/terraform-#{@version}/)
        end
      end
      context 'VersionManager has not installed binaries' do
        it 'returns the default value' do
          expect(subject.binary).to eq('terraform')
        end
      end
    end

    describe '#version' do
      it 'returns the default value' do
        expect(subject.version).to be_nil
      end
    end

    describe '#autoinstall' do
      it 'returns the default value' do
        expect(subject.seatbelt).to be_falsey
      end
    end

    describe '#quiet' do
      it 'returns the default value' do
        expect(subject.quiet).to be_falsey
      end
    end

    describe '#echo' do
      it 'returns the default value' do
        expect(subject.echo).to be_falsey
      end
    end

    describe '#environment' do
      it 'returns the default value' do
        expect(subject.environment).to be_a(Hash)
      end
    end
  end

  context 'block initalization' do
    let(:options) do
      described_class.new do |obj|
        obj.foo = 'foo'
        obj.bar = 'bar'
      end
    end

    describe '#new with block' do
      it 'creates and inserts values' do
        expect(options.foo).to eq('foo')
        expect(options.bar).to eq('bar')
      end
    end
  end

  context 'post-init configuration' do
    describe '#path=' do
      it 'sets the value' do
        subject.path = 'foo'
        expect(subject.path).to eq('foo')
      end
    end

    describe '#version=' do
      it 'sets the value' do
        subject.version = '0.0.0'
        expect(subject.version).to eq('0.0.0')
      end
    end
  end
end
