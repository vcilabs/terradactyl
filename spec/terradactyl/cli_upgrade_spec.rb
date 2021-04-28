require 'spec_helper'

RSpec.describe Terradactyl::CLI do
  Helpers.terraform_test_matrix.each do |rev, info|
    if info[:upgradeable]
      context "when stack is upgradeable (#{rev})" do
        describe 'upgrade' do
          let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

          let(:version) { info[:version] }

          let(:stack_name) { rev }

          let(:command) do
            exe("terradactyl upgrade #{stack_name}", tmpdir)
          end

          let(:artifact) { "#{tmpdir}/stacks/#{stack_name}/#{info[:artifacts][:upgrade]}"  }

          before(:each) do
            cp_fixtures(tmpdir)
          end

          it 'upgrades the stack' do
            expect(command.stdout).to include 'Upgraded'
            expect(File.exist?(artifact)).to be_falsey
            expect(command.exitstatus).to eq(0)
          end
        end
      end
    else
      context "when stack is non-upgradeable (#{rev})" do
        describe 'upgrade' do
          let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

          let(:version) { info[:version] }

          let(:stack_name) { rev }

          let(:command) do
            exe("terradactyl upgrade #{stack_name}", tmpdir)
          end

          before(:each) do
            cp_fixtures(tmpdir)
          end

          it 'raises an error' do
            expect(command.stdout).to include 'Error'
            expect(command.exitstatus).not_to eq(0)
          end
        end
      end
    end
  end
end
