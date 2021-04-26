require 'spec_helper'

RSpec.describe Terradactyl::ConfigStack do
  let(:stack_name) { 'rev011' }
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
    let(:stack_name) { 'configless' }
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

    context 'when a Terraform version is expressed in .tf' do
      describe '#terraform.version' do
        let(:terraform_settings) do
          <<~LINT_ME

            terraform {

              required_providers {
                archive = {
                  source = "hashicorp/archive"
                }
                aws = {
                  source = "hashicorp/aws"
                }
              }

              required_version = ">= 0.13"
            }

          LINT_ME
        end

        before do
          FileUtils.mkdir_p("stacks/#{stack_name}")
          File.write("stacks/#{stack_name}/settings.tf", terraform_settings)
        end

        after do
          FileUtils.rm_rf("stacks/#{stack_name}")
        end

        it 'returns the version specified by Terraform settings' do
          expect(subject.terraform.version).to eq(">= 0.13")
        end
      end
    end
  end

  context 'when stack-level config file _is_ present' do
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

    context 'when a Terraform version is expressed in .tf' do
      describe '#terraform.version' do
        let(:terraform_settings) do
          <<~LINT_ME

            terraform {

              required_providers {
                archive = {
                  source = "hashicorp/archive"
                }
                aws = {
                  source = "hashicorp/aws"
                }
              }

              required_version = ">= 0.13"
            }

          LINT_ME
        end

        before do
          FileUtils.mkdir_p("stacks/#{stack_name}")
          File.write("stacks/#{stack_name}/settings.tf", terraform_settings)
        end

        after do
          FileUtils.rm_rf("stacks/#{stack_name}")
        end

        it 'returns the version specified by Terradactyl' do
          expect(subject.terraform.version).to eq(terraform_legacy)
        end
      end
    end
  end
end
