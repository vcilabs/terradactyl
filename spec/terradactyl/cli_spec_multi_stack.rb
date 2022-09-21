require 'spec_helper'

def multistack_test_matrix
  {
    no_override: {
      base_folder: 'stacks',
      base_override: nil
    },
    base_override: {
      base_folder: 'nested',
      base_override: 'nested'
    }
  }
end

RSpec.describe Terradactyl::CLI do
  multistack_test_matrix.each do |rev, info|
    context "Terraform Multi-stack operations with #{rev}" do
      let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

      let(:base_folder) { info[:base_folder] }
      let(:base_override) { info[:base_override] }

      let(:known_stacks) { Dir["#{tmpdir}/#{base_folder}/*/"] }

      let(:num_of_stacks) { known_stacks.size }

      before(:each) do
        cp_fixtures(tmpdir)
      end

      describe "plan_all" do
        let(:command) do
          exe("terradactyl plan-all #{base_override}", tmpdir)
        end

        it 'plans multiple stacks' do
          expect(command.stdout).to include 'Planning ALL Stacks'
          expect(command.exitstatus).to eq(0)
        end
      end

      describe "smartapply" do
        context 'when no plan files are present' do
          let(:command) do
            exe("terradactyl smartapply #{base_override}", tmpdir)
          end

          it 'applies NO stacks' do
            expect(command.stdout).to include 'No stacks contain plan files'
            expect(command.exitstatus).to eq(0)
          end
        end

        context 'when the stacks have plan files' do
          before do
            silence do
              pwd = Dir.pwd
              Dir.chdir tmpdir
              described_class.new.plan_all(base_override)
              Dir.chdir pwd
            end
          end

          let(:command) do
            exe("terradactyl smartapply #{base_override}", tmpdir)
          end

          it 'applies multiple stacks' do
            expect(command.stdout).to include "Total Stacks Modified: #{num_of_stacks}"
            expect(command.exitstatus).to eq(0)
          end
        end
      end

      describe "smartrefresh" do
        context 'when the stacks have plan files' do
          before do
            silence do
              pwd = Dir.pwd
              Dir.chdir tmpdir
              described_class.new.plan_all(base_override)
              described_class.new.smartapply(base_override)
              Dir.chdir pwd
            end
          end

          let(:command) do
            exe("terradactyl smartrefresh #{base_override}", tmpdir)
          end

          it 'refreshes multiple stacks' do
            expect(command.stdout).to include "Total Stacks Refreshed: #{num_of_stacks}"
            expect(command.exitstatus).to eq(0)
          end
        end
      end

      describe "audit_all" do
        context 'without report flag' do
          let(:command) do
            exe("terradactyl audit-all #{base_override}", tmpdir)
          end

          it 'audits all stacks' do
            expect(command.stdout).to include 'Auditing ALL Stacks'
            expect(command.exitstatus).to eq(1)
          end
        end

        context 'with report flag' do
          let(:command) do
            exe("terradactyl audit-all #{base_override} --report", tmpdir)
          end

          let(:report) do
            "#{tmpdir}/#{base_folder}.audit.json"
          end

          it 'audits all stacks and produces a report' do
            expect(command.stdout).to include 'Auditing ALL Stacks'
            expect(command.exitstatus).to eq(1)
            expect(File.exist?(report)).to be_truthy
          end
        end
      end

      describe "clean_all" do
        let(:command) do
          exe("terradactyl clean-all #{base_override}", tmpdir)
        end

        it 'cleans multiple stacks' do
          expect(command.stdout).to include 'Cleaning ALL Stacks'
          expect(command.exitstatus).to eq(0)
        end
      end
    end
  end
end
