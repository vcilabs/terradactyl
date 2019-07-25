require 'spec_helper'

RSpec.describe Terradactyl::ConfigProject do

  context 'when project-level config file is NOT present' do

    # Step into a directory that contains no project file
    before(:each) do
      FileUtils.cd '..'
    end

    # Restore to working directory
    after(:each) do
      FileUtils.cd './fixtures'
    end

    subject { Class.new(described_class).instance }

    it 'aborts to program' do
      silence do
        expect { subject }.to raise_error(SystemExit, /Could not load.*/)
      end
    end

  end

  context 'when project-level config file _is_ present' do

    subject { Class.new(described_class).instance }

    describe '#terradactyl' do
      it 'returns Terradactyl config data' do
        expect(subject.terradactyl).to be_a(OpenStruct)
      end
    end

    describe '#terraform' do
      it 'returns Terraform config data' do
        expect(subject.terraform).to be_a(OpenStruct)
        expect(subject.terraform.version).to eq(terraform_minimum)
      end

      it 'merges subkeys on values that are Hash objects' do
        expect(subject.terraform.init).to be_a(OpenStruct)
        expect(subject.terraform.init.instance_variable_get("@table").keys.size).to eq(3)
        expect(subject.terraform.init.no_color).to be_truthy
      end
    end

    describe '#environment' do
      it 'returns Environment variables' do
        expect(subject.environment).to be_a(OpenStruct)
        expect(subject.environment.FOO).to eq('foo')
      end
    end

    describe '#cleanup' do
      it 'returns Cleanup config data' do
        expect(subject.cleanup).to be_a(OpenStruct)
      end

      it 'overwrites subkeys on values that are Array objects' do
        expect(subject.cleanup.match).to be_a(Array)
        expect(subject.cleanup.match.size).to eq(4)
      end
    end

    describe '#misc' do
      it 'returns Misc config data' do
        expect(subject.misc).to be_a(OpenStruct)
        expect(subject.misc.utf8).to be_falsey
      end
    end

    describe '#reload' do

      before(:each) do
        subject.terraform.version = '0.0.0'
      end

      it 'reloads all the configs' do
        expect(subject.reload).to be_a(OpenStruct)
        expect(subject.terraform.version).to eq(terraform_minimum)
      end
    end

  end

end
