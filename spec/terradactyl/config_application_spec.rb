require 'spec_helper'

RSpec.describe Terradactyl::ConfigApplication do
  let(:config_file) { 'terradactyl.yaml' }
  let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

  before(:each) do
    cp_fixtures(tmpdir)
    Dir.chdir(tmpdir)
  end

  after(:each) do
    Dir.chdir(original_work_dir)
  end

  context 'initialization' do
    context 'when config file is supplied' do
      describe 'defaults are merged' do
        let(:instance)    { described_class.new(config_file) }
        it 'loads the config' do
          expect(instance.terraform.version).to eq(terraform_minimum)
        end
      end
    end

    context 'when config file NOT supplied' do
      describe 'defaults are NOT supplied' do
        let(:instance) { described_class.new }
        it 'loads internal defaults' do
          expect(instance.terraform.version).to be_nil
        end
      end

      describe 'defaults are supplied' do
        let(:defaults) { YAML.load_file(config_file) }
        let(:instance) { described_class.new(defaults: defaults) }
        it 'loads custom defaults' do
          expect(instance.terraform.version).to eq(terraform_minimum)
        end
      end
    end
  end

  context 'accessors' do
    let(:instance) { described_class.new }

    before(:each) do
      instance.environment.FOO = 'foo'
      instance.cleanup.match = %w[
        *.tfstate*
        *.tfout
        *.zip
        .terraform
      ]
      instance.misc.utf8 = false
    end

    after(:each) do
      instance.reload
    end

    describe '#terradactyl' do
      it 'returns Terradactyl config data' do
        expect(instance.terradactyl).to be_a(OpenStruct)
      end
    end

    describe '#terraform' do
      it 'returns Terraform config data' do
        expect(instance.terraform).to be_a(OpenStruct)
        expect(instance.terraform.binary).to be_nil
        expect(instance.terraform.version).to be_nil
        expect(instance.terraform.autoinstall).to be_nil
        expect(instance.terraform.install_dir).to be_nil
      end

      it 'merges subkeys on values that are OpenStruct objects' do
        expect(instance.terraform.init).to be_a(OpenStruct)
        expect(instance.terraform.init.instance_variable_get("@table").keys.size).to eq(2)
        expect(instance.terraform.init.lock).to be_falsey
      end
    end

    describe '#environment' do
      it 'returns Environment variables' do
        expect(instance.environment).to be_a(OpenStruct)
        expect(instance.environment.FOO).to eq('foo')
      end
    end

    describe '#cleanup' do
      it 'returns Cleanup config data' do
        expect(instance.cleanup).to be_a(OpenStruct)
      end

      it 'overwrites subkeys on values that are Array objects' do
        expect(instance.cleanup.match).to be_a(Array)
        expect(instance.cleanup.match.size).to eq(4)
      end
    end

    describe '#misc' do
      it 'returns Misc config data' do
        expect(instance.misc).to be_a(OpenStruct)
        expect(instance.misc.utf8).to be_falsey
      end
    end

    describe '#reload' do
      it 'reloads all the configs' do
        expect(instance.reload).to be_a(OpenStruct)
        expect(instance.terraform.version).to be_nil
        expect(instance.terraform.init.lock).to be_falsey
        expect(instance.environment).not_to respond_to('FOO')
        expect(instance.cleanup.match).to include('*.tflock')
        expect(instance.misc.utf8).to be_truthy
      end
    end
  end
end
