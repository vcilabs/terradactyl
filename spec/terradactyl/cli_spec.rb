require 'spec_helper'

RSpec.describe Terradactyl::CLI do

  # Fixtures to copy, the whole working directory
  fixture_file('.')

  # Sets the parent directory for rspec-command
  # - useful for testing
  # let(:temp_path) { 'tmp' }

  let(:unlinted) do
    <<~LINT_ME
      resource "null_resource" "unlinted"
      {}
    LINT_ME
  end

  after(:each) do
    silence { described_class.new.clean_all }
  end

  describe 'stacks' do
    command('terradactyl stacks')
    its(:stdout) { is_expected.to include '* stack_a' }
    its(:exitstatus) { is_expected.to eq 0 }
  end

  describe 'version' do
    command('terradactyl version')
    its(:stdout) { is_expected.to include "version: #{Terradactyl::VERSION}" }
    its(:exitstatus) { is_expected.to eq 0 }
  end

  describe 'quickplan' do
    context 'with no args' do
      command('terradactyl quickplan', allow_error: true)
      its(:stderr) { is_expected.to match /ERROR.* was called with no arguments/ }
      its(:exitstatus) { is_expected.to eq 1 }
    end

    context 'with invalid stack_name' do
      command('terradactyl quickplan foo', allow_error: true)
      its(:stdout) { is_expected.to include 'Stack not found' }
      its(:exitstatus) { is_expected.to eq 1 }
    end

    context 'with valid stack_name' do
      command('terradactyl quickplan stack_a')
      its(:stdout) { is_expected.to include 'Plan: 1 to add, 0 to change, 0 to destroy.' }
      its(:exitstatus) { is_expected.to eq 0 }
    end

    context 'with valid relative path' do
      command('terradactyl quickplan stacks/stack_a')
      its(:stdout) { is_expected.to include 'Plan: 1 to add, 0 to change, 0 to destroy.' }
      its(:exitstatus) { is_expected.to eq 0 }
    end
  end

  describe 'plan_all' do
    command('terradactyl plan-all')
    its(:stdout) { is_expected.to include 'Planning ALL Stacks ...' }
    its(:exitstatus) { is_expected.to eq 0 }
  end

  describe 'clean_all' do
    command('terradactyl clean-all')
    its(:stdout) { is_expected.to include 'Cleaning ALL Stacks ...' }
    its(:exitstatus) { is_expected.to eq 0 }
  end

  describe 'smartapply' do
    context 'when no plan files are present' do
      command('terradactyl smartapply')
      its(:stdout) { is_expected.to include 'No stacks contain plan files ...' }
      its(:exitstatus) { is_expected.to eq 0 }
    end

    context 'when the stacks have plan files' do
      before { silence { described_class.new.plan_all } }
      fixture_file('.')
      command('terradactyl smartapply')
      its(:stdout) { is_expected.to include 'Total Stacks Modified: 3' }
      its(:exitstatus) { is_expected.to eq 0 }
    end
  end

  describe 'smartrefresh' do
    context 'when the stacks have plan files' do
      before do
        silence do
          described_class.new.plan_all
          described_class.new.smartapply
        end
      end
      fixture_file('.')
      command('terradactyl smartrefresh')
      its(:stdout) { is_expected.to include 'Total Stacks Refreshed: 3' }
      its(:exitstatus) { is_expected.to eq 0 }
    end
  end

  describe 'audit_all' do
    context 'without report' do
      fixture_file('.')
      command('terradactyl audit-all', allow_error: true)
      its(:stdout) { is_expected.to include 'Auditing ALL Stacks ...' }
      its(:exitstatus) { is_expected.to eq 1 }
    end

    context 'with report' do
      module Mixlib
        class ShellOut
          def has_report?
            File.exist?("#{cwd}/stacks.audit.json")
          end
        end
      end
      fixture_file('.')
      command('terradactyl audit-all --report', allow_error: true)
      its(:stdout) { is_expected.to include 'Auditing ALL Stacks ...' }
      its(:exitstatus)  { is_expected.to eq 1 }
      its(:has_report?) { is_expected.to be_truthy }
    end
  end

  describe 'lint' do
    context 'stack requires no formatting' do
      command('terradactyl lint stack_a')
      its(:stdout) { is_expected.to include 'Formatting OK' }
      its(:exitstatus) { is_expected.to eq 0 }
    end

    context 'stack requires formatting' do
      file 'stacks/stack_a/unlinted.tf' do
         unlinted
      end
      command('terradactyl lint stack_a', allow_error: true)
      its(:stdout) { is_expected.to include 'Bad Formatting' }
      its(:exitstatus) { is_expected.to eq 1 }
    end
  end

  describe 'fmt' do
    command('terradactyl fmt stack_a')
    its(:stdout) { is_expected.to include 'Formatted' }
    its(:exitstatus) { is_expected.to eq 0 }
  end
end
