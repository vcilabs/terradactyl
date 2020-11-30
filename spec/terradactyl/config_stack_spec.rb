require 'spec_helper'

RSpec.describe Terradactyl::ConfigStack do
  let(:stack_name) { 'stack_a' }
  let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

  before(:each) do
    cp_fixtures(tmpdir)
    Dir.chdir(tmpdir)
    Terradactyl::ConfigProject.instance.reload
  end

  after(:each) do
    Dir.chdir(original_work_dir)
  end

  subject { described_class.new(stack_name) }

  describe 'basic getters' do
    it 'returns basic stack attribs' do
      expect(subject.stack_name).to eq(stack_name)
      expect(subject.base_folder).to eq('stacks')
      expect(subject.stack_path).to match(/#{stack_name}/)
      expect(subject.plan_file).to eq("#{stack_name}.tfout")
      expect(subject.plan_path).to eq("#{subject.stack_path}/#{stack_name}.tfout")
      expect(subject.state_path).to eq("#{subject.stack_path}/terraform.tfstate")
      expect(subject.state_file).to eq('terraform.tfstate')
    end
  end

  context 'when stack-level config file is NOT present' do
    let(:stack_name) { 'stack_c' }

    subject { described_class.new(stack_name) }

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
    end
  end

  context 'when stack-level config file _is_ present' do
    let(:stack_name) { 'stack_a' }

    subject { described_class.new(stack_name) }

    describe '#terradactyl' do
      it 'returns Terradactyl config data' do
        expect(subject.terradactyl).to be_a(OpenStruct)
      end
    end

    describe '#terraform' do
      it 'returns Terraform config data' do
        expect(subject.terraform.version).to eq(terraform_legacy)
      end
    end

    describe '#environment' do
      it 'returns Environment config data' do
        expect(subject.environment.FOO).to eq('foo')
      end
    end

    describe '#base_folder' do
      it 'ignores the stack-level config' do
        expect(subject.base_folder).to eq('stacks')
      end
    end
  end
end
