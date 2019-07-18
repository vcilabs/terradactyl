require 'spec_helper'

RSpec.describe Terradactyl::Terraform::VersionManager::Binary do
  let(:latest_version) { Terradactyl::Terraform::VersionManager.latest }

  context 'with no args' do
    before(:all) do
      Terradactyl::Terraform::VersionManager.list.each do |path|
        FileUtils.rm path
      end
    end

    after(:all) do
      Terradactyl::Terraform::VersionManager.list.each do |path|
        FileUtils.rm path
      end
    end

    describe '#initialize' do
      it 'returns an Binary obj' do
        expect(subject).to be_a(described_class)
      end
    end

    describe '#version' do
      it 'references the latest version' do
        expect(subject.version).to eq(latest_version)
      end
    end

    describe 'installation and removal' do
      context 'when not installed' do
        it 'remove does nothing' do
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.remove).to be_falsey
          expect(File.exist?(subject.install_path)).to be_falsey
          expect(subject.installed?).to be_falsey
        end

        it 'installs the package' do
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.install).to eq(subject.install_path)
          expect(File.exist?(subject.install_path)).to be_truthy
          expect(File.stat(subject.install_path).mode).to eq(33261)
          expect(File.exist?(subject.download)).to be_falsey
        end
      end

      context 'when already installed' do
        it 'install does nothing' do
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.install).to eq(subject.install_path)
          expect(File.exist?(subject.install_path)).to be_truthy
          expect(File.stat(subject.install_path).mode).to eq(33261)
          expect(File.exist?(subject.download)).to be_falsey
        end

        it 'removes the package' do
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.remove).to be_truthy
          expect(File.exist?(subject.install_path)).to be_falsey
          expect(subject.installed?).to be_falsey
        end
      end
    end
  end

  context 'with valid args' do
    let(:subject) { described_class.new(version: terraform_minimum) }

    describe '#initialize' do
      it 'returns an Binary obj' do
        expect(subject).to be_a (described_class)
      end
    end

    describe '#version' do
      it 'returns the targeted version' do
        expect(subject.version).to eq(terraform_minimum)
      end
    end

    describe '#installed?' do
      it 'returns boolean' do
        expect(subject.installed?).to be_falsey
      end
    end

    describe '#install' do
      context 'when not installed' do
        it 'downloads installs the package to the install_dir' do
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.install).to be_truthy
          expect(File.exist?(subject.install_path)).to be_truthy
          expect(File.stat(subject.install_path).mode).to eq(33261)
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.installed?).to be_truthy
          cmd_output =`#{subject.install_path}`
          exit_code  = $?.exitstatus
          expect(cmd_output).to match(/Usage: terraform/)
          expect(exit_code).to eq(127)
        end
      end

      context 'when installed' do
        it 'does nothing' do
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.install).to eq(subject.install_path)
          expect(File.exist?(subject.install_path)).to be_truthy
          expect(subject.installed?).to be_truthy
        end
      end
    end

    describe '#remove' do
      context 'when already installed' do
        it 'removes the binary' do
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.remove).to be_truthy
          expect(File.exist?(subject.install_path)).to be_falsey
          expect(subject.installed?).to be_falsey
        end
      end

      context 'when not installed' do
        it 'does nothing' do
          expect(File.exist?(subject.download)).to be_falsey
          expect(subject.remove).to be_falsey
          expect(File.exist?(subject.install_path)).to be_falsey
          expect(subject.installed?).to be_falsey
        end
      end
    end
  end
end
