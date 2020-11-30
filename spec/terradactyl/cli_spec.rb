require 'spec_helper'

RSpec.describe Terradactyl::CLI do

  let(:unlinted) do
    <<~LINT_ME
      resource "null_resource" "unlinted"
      {}
    LINT_ME
  end

  let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

  let(:num_of_stacks) { Dir["#{tmpdir}/stacks/*"].size }

  before(:each) do
    cp_fixtures(tmpdir)
  end

  describe 'defaults' do
    let(:command) do
      exe('terradactyl defaults', tmpdir)
    end

    it 'displays the compiled Terradactyl configuration' do
      expect(command.stdout).to include 'base_folder: stacks'
      expect(command.exitstatus).to eq(0)
    end
  end

  describe 'stacks' do
    let(:command) do
      exe('terradactyl stacks', tmpdir)
    end

    it 'displays a list of Terraform stacks' do
      expect(command.stdout).to include '* stack_a'
      expect(command.exitstatus).to eq(0)
    end
  end

  describe 'version' do
    let(:command) do
      exe('terradactyl version', tmpdir)
    end

    it 'displays the Terradactyl version' do
      expect(command.stdout).to include "version: #{Terradactyl::VERSION}"
      expect(command.exitstatus).to eq(0)
    end
  end

  describe 'quickplan' do
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
        exe('terradactyl quickplan stack_a', tmpdir)
      end

      it 'displays a plan' do
        expect(command.stdout).to include 'Plan: 1 to add, 0 to change, 0 to destroy.'
        expect(command.exitstatus).to eq(0)
      end
    end

    context 'with valid relative path' do
      let(:command) do
        exe('terradactyl quickplan stacks/stack_a', tmpdir)
      end

      it 'displays a plan' do
        expect(command.stdout).to include 'Plan: 1 to add, 0 to change, 0 to destroy.'
        expect(command.exitstatus).to eq(0)
      end
    end
  end

  describe 'plan_all' do
    let(:command) do
      exe('terradactyl plan-all', tmpdir)
    end

    it 'plans multiple stacks' do
      expect(command.stdout).to include 'Planning ALL Stacks ...'
      expect(command.exitstatus).to eq(0)
    end
  end

  describe 'clean_all' do
    let(:command) do
      exe('terradactyl clean-all', tmpdir)
    end

    it 'cleans multiple stacks' do
      expect(command.stdout).to include 'Cleaning ALL Stacks ...'
      expect(command.exitstatus).to eq(0)
    end
  end

  describe 'smartapply' do
    context 'when no plan files are present' do
      let(:command) do
        exe('terradactyl smartapply', tmpdir)
      end

      it 'applies NO stacks' do
        expect(command.stdout).to include 'No stacks contain plan files ...'
        expect(command.exitstatus).to eq(0)
      end
    end

    context 'when the stacks have plan files' do
      before do
        silence do
          pwd = Dir.pwd
          Dir.chdir tmpdir
          described_class.new.plan_all
          Dir.chdir pwd
        end
      end

      let(:command) do
        exe('terradactyl smartapply', tmpdir)
      end

      it 'applies multiple stacks' do
        expect(command.stdout).to include "Total Stacks Modified: #{num_of_stacks}"
        expect(command.exitstatus).to eq(0)
      end
    end
  end

  describe 'smartrefresh' do
    context 'when the stacks have plan files' do
      before do
        silence do
          pwd = Dir.pwd
          Dir.chdir tmpdir
          described_class.new.plan_all
          described_class.new.smartapply
          Dir.chdir pwd
        end
      end

      let(:command) do
        exe('terradactyl smartrefresh', tmpdir)
      end

      it 'refreshes multiple stacks' do
        expect(command.stdout).to include "Total Stacks Refreshed: #{num_of_stacks}"
        expect(command.exitstatus).to eq(0)
      end
    end
  end

  describe 'audit_all' do
    context 'without report flag' do
      let(:command) do
        exe('terradactyl audit-all', tmpdir)
      end

      it 'audits all stacks' do
        expect(command.stdout).to include 'Auditing ALL Stacks ...'
        expect(command.exitstatus).to eq(1)
      end
    end

    context 'with report flag' do
      let(:command) do
        exe('terradactyl audit-all  --report', tmpdir)
      end

      let(:report) do
        "#{tmpdir}/stacks.audit.json"
      end

      it 'audits all stacks and produces a report' do
        expect(command.stdout).to include 'Auditing ALL Stacks ...'
        expect(command.exitstatus).to eq(1)
        expect(File.exist?(report)).to be_truthy
      end
    end
  end

  describe 'lint' do
    context 'stack requires no formatting' do
      let(:command) do
        exe('terradactyl lint stack_a', tmpdir)
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
        File.write('stacks/stack_a/unlinted.tf', unlinted)
        Dir.chdir pwd
      end

      let(:command) do
        exe('terradactyl lint stack_a', tmpdir)
      end

      it 'displays a formatting error' do
        expect(command.stdout).to include 'Bad Formatting'
        expect(command.exitstatus).to eq(1)
      end
    end
  end

  describe 'fmt' do
    let(:command) do
      exe('terradactyl fmt stack_a', tmpdir)
    end

    it 'displays a formatting error' do
      expect(command.stdout).to include 'Formatted'
      expect(command.exitstatus).to eq(0)
    end
  end
end
