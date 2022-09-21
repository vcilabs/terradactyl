require 'spec_helper'

RSpec.describe Terradactyl::CLI do
  Helpers.terraform_test_matrix.each do |rev, info|
    context "Terraform #{rev}, #{info[:version]}" do
      let(:unlinted) do
        <<~LINT_ME
          resource "null_resource" "unlinted"{}
        LINT_ME
      end

      let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

      let(:known_stacks) { Dir["#{tmpdir}/stacks/*"] }

      let(:num_of_stacks) { known_stacks.size }

      let(:base_override) { info[:base_override] }

      # let(:target_stack) { known_stacks.shuffle.first }
      let(:target_stack) { 
        base_override ? "#{tmpdir}/#{base_override}/#{rev}" : "#{tmpdir}/stacks/#{rev}"
      }

      before(:each) do
        cp_fixtures(tmpdir)
      end

      describe "defaults (#{rev})" do
        let(:command) do
          exe('terradactyl defaults', tmpdir)
        end

        it 'displays the compiled Terradactyl configuration' do
          expect(command.stdout).to include 'base_folder: stacks'
          expect(command.exitstatus).to eq(0)
        end
      end

      describe "stacks (#{rev})" do
        let(:command) do
          exe("terradactyl stacks #{base_override}", tmpdir)
        end

        it 'displays a list of Terraform stacks' do
          expect(command.stdout).to include '* rev'
          expect(command.exitstatus).to eq(0)
        end
      end

      describe "version (#{rev})" do
        let(:command) do
          exe("terradactyl version", tmpdir)
        end

        it 'displays the Terradactyl version' do
          expect(command.stdout).to include "version: #{Terradactyl::VERSION}"
          expect(command.exitstatus).to eq(0)
        end
      end

      describe "quickplan (#{rev})" do
        context 'with no args' do
          let(:command) do
            exe('terradactyl quickplan', tmpdir)
          end

          it 'displays an arg error' do
            expect(command.stderr).to match /ERROR.* was called with no arguments/
            expect(command.exitstatus).to eq(1)
          end
        end

        context 'with invalid stack_name' do
          let(:command) do
            exe('terradactyl quickplan foo', tmpdir)
          end

          it 'displays not found error' do
            expect(command.stdout).to include 'Stack not found'
            expect(command.exitstatus).to eq(1)
          end
        end

        context 'with valid stack_name' do
          let(:command) do
            exe("terradactyl quickplan #{target_stack} #{base_override}", tmpdir)
          end

          it 'displays a plan' do
            expect(command.stdout).to include 'Plan: 1 to add, 0 to change, 0 to destroy.'
            expect(command.exitstatus).to eq(0)
          end
        end

        context 'with valid relative path' do
          let(:command) do
              exe("terradactyl quickplan #{base_override || 'stacks'}/#{target_stack} #{base_override}", tmpdir)
          end

          it 'displays a plan' do
            expect(command.stdout).to include 'Plan: 1 to add, 0 to change, 0 to destroy.'
            expect(command.exitstatus).to eq(0)
          end
        end
      end

      describe "lint (#{rev})" do
        context 'stack requires no formatting' do
          let(:command) do
            exe("terradactyl lint #{target_stack} #{base_override}", tmpdir)
          end

          it 'does nothing' do
            expect(command.stdout).to include 'Formatting OK'
            expect(command.exitstatus).to eq(0)
          end
        end

        context 'stack requires formatting' do
          before do
            pwd = Dir.pwd
            Dir.chdir tmpdir
            File.write("#{target_stack}/unlinted.tf", unlinted)
            Dir.chdir pwd
          end

          let(:command) do
            exe("terradactyl lint #{target_stack} #{base_override}", tmpdir)
          end

          it 'displays a formatting error' do
            expect(command.stdout).to include 'Bad Formatting'
            expect(command.exitstatus).to eq(1)
          end
        end
      end

      describe "fmt (#{rev})" do
        let(:command) do
          exe("terradactyl fmt #{target_stack} #{base_override}", tmpdir)
        end

        it 'displays a formatting error' do
          expect(command.stdout).to include 'Formatted'
          expect(command.exitstatus).to eq(0)
        end
      end

      describe "install(#{rev})" do
        describe 'terraform' do
          after(:all) do
            Terradactyl::Terraform::VersionManager.binaries.each do |file|
              FileUtils.rm_rf file
            end
            Terradactyl::Terraform::VersionManager.reset!
          end

          let(:valid_expressions) {
            {
              ''                                   => /terraform-#{terraform_latest}/,
              %q{--version="~> 0.14.0"}            => /terraform-0\.14\.\d+/,
              %q{--version=">= 0.13.0, <= 0.14.0"} => /terraform-0\.14\.\d+/,
              %q{--version="= 0.11.14"}            => /terraform-0\.11\.14/,
            }
          }

          let(:invalid_expressions) {
            {
              %q{--version="~>"}                  => 'Invalid version string',
              %q{--version=">= 0.13.0, <=0.14.0"} => 'Unparsable version string',
              %q{--version="0"}                   => 'Invalid version string',
            }
          }

          context 'when passed a bad version expression' do
            it 'raises an exception' do
              invalid_expressions.each do |exp, re|
                cmd = exe("terradactyl install terraform #{exp}", tmpdir)
                expect(cmd.stderr).to match(re)
                expect(cmd.exitstatus).not_to eq(0)
              end
            end
          end

          context 'when passed a valid version expression' do
            it 'installs the expected version' do
              valid_expressions.each do |exp, re|
                cmd = exe("terradactyl install terraform #{exp}", tmpdir)
                expect(cmd.stdout).to match(re)
                expect(cmd.exitstatus).to eq(0)
              end
            end
          end
        end
      end

      describe "upgrade (#{rev})" do
        let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

        let(:current_version) { info[:version] }
        let(:upgrade_version) { calculate_upgrade(current_version) }

        let(:stack_name) { rev.to_s }

        let(:command) do
          exe("terradactyl upgrade #{stack_name} #{base_override}", tmpdir)
        end

        let(:config)   { "#{tmpdir}/#{base_override || 'stacks'}/#{stack_name}/terradactyl.yaml" }
        let(:versions) { "#{tmpdir}/#{base_override || 'stacks'}/#{stack_name}/versions.tf" }

        before(:each) do
          cp_fixtures(tmpdir)
        end

        context 'when the stack is upgradeable' do
          if info[:upgradeable]
            it 'upgrades the stack' do
              expect(command.stdout).to include 'Upgraded'
              expect(File.exist?(config)).to be_falsey
              expect(File.exist?(versions)).to be_truthy
              expect(File.read(versions)).to match(/required_version\s=\s"~>/)
              expect(command.exitstatus).to eq(0)
            end
          end
        end

        context 'when the stack is NOT upgradeable' do
          unless info[:upgradeable]
            it 'raises an error' do
              expect(command.stdout).to include 'Error'
              expect(command.exitstatus).not_to eq(0)
            end
          end
        end
      end
    end
  end
end
