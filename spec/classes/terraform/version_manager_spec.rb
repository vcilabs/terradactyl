require 'spec_helper'

RSpec.describe Terradactyl::Terraform::VersionManager do

  before(:all) do
    @install_dir = Terradactyl::Terraform::VersionManager.install_dir
    Dir.glob("#{@install_dir}/terraform-*").each do |path|
      FileUtils.rm path
    end
  end

  after(:all) do
    Dir.glob("#{@install_dir}/terraform-*").each do |path|
      FileUtils.rm path
    end
    described_class.reset!
  end

  let(:test_versions) { %w[0.11.14 0.12.2] }

  context 'global configuration' do

    before(:each) do
      @temp_dir = Dir.mktmpdir('terradactyl')
    end

    after(:each) do
      FileUtils.rm_rf @temp_dir
      subject.reset!
    end

    it 'responds to requests for options' do
      expect(subject.install_dir).to eq(Gem.bindir)
      expect(subject.downloads_url).to eq('https://www.terraform.io/downloads.html')
      expect(subject.releases_url).to eq('https://releases.hashicorp.com/terraform')
    end

    describe 'block configuration' do
      it 'accepts a block of configuration options' do
        expect(subject.options { |c| c.install_dir = @temp_dir}).to eq(@temp_dir)
        expect(subject.install_dir).to eq(@temp_dir)
      end
    end

    describe 'direct configuration' do
      it 'accepts a block of configuration options' do
        expect(subject.install_dir = @temp_dir).to eq(@temp_dir)
        expect(subject.install_dir).to eq(@temp_dir)
      end
    end
  end

  context 'inventory control' do
    describe '#latest' do
      it 'returns the latest version of terraform' do
        expect(subject.latest).to match(/0\.12\.\d+/)
      end
    end

    context 'default install_dir' do
      describe '#install' do
        it 'installs the specified version of Terraform' do
          test_versions.each do |semver|
            expect(subject.install(semver)).to be_truthy
            expect(File.exist?(subject[semver])).to be_truthy
            expect(File.stat(subject[semver]).mode).to eq(33261)
            cmd_output =`#{subject[semver]}`
            exit_code  = $?.exitstatus
            expect(cmd_output).to match(/Usage: terraform/)
            expect(exit_code).to eq(127)
          end
        end
      end

      describe '#list' do
        it 'provides a list of accessible terraform binaries' do
          expect(subject.list).to be_a(Array)
          expect(subject.list.size).to eq(test_versions.size)
        end
      end

      describe '#inventory' do
        it 'provides a table of accessible binaries by version' do
          expect(subject.inventory).to be_a(Hash)
          expect(subject.inventory.size).to eq(test_versions.size)
        end
        it 'accepts a semver string to lookup' do
          test_versions.each do |version|
            expect(subject.inventory(version)).to match(/terraform-#{version}/)
          end
        end
      end

      describe '#[]' do
        it 'does an inventory lookup' do
          expect(subject['0.0.0']).to be_nil
          test_versions.each do |version|
            expect(subject[version]).to match(/terraform-#{version}/)
          end
        end
      end

      describe '#search' do
        context 'when none are installed' do
          before do
            @temp_dir = Dir.mktmpdir('terradactyl')
            Terradactyl::Terraform::VersionManager.options do |option|
              option.install_dir = @temp_dir
            end
          end

          after do
            FileUtils.rm_rf @temp_dir
            described_class.reset!
          end

          it 'returns forces terraform lookup on $PATH' do
            expect(subject.search).to eq('terraform')
          end
        end

        context 'when none are installed' do
          it 'returns first result from install dir' do
            expect(subject.search).to eq(subject.inventory(test_versions.first))
          end
        end
      end

      describe '#remove' do
        it 'removes the specified version of Terraform' do
          test_versions.each do |semver|
            binary = subject[semver]
            expect(File.exist?(binary)).to be_truthy
            expect(subject.remove(semver)).to be_truthy
            expect(File.exist?(binary)).to be_falsey
          end
        end
      end
    end
  end

  context 'custom install_dir' do
    before(:all) do
      @temp_dir = Dir.mktmpdir('terradactyl')
      Terradactyl::Terraform::VersionManager.options do |option|
        option.install_dir = @temp_dir
      end
    end

    after(:all) do
      FileUtils.rm_rf @temp_dir
      described_class.reset!
    end

    describe '#install' do
      it 'installs the specified version of Terraform' do
        test_versions.each do |semver|
          expect(subject.install(semver)).to be_truthy
          expect(File.exist?(subject[semver])).to be_truthy
          expect(File.stat(subject[semver]).mode).to eq(33261)
          cmd_output =`#{subject[semver]}`
          exit_code  = $?.exitstatus
          expect(cmd_output).to match(/Usage: terraform/)
          expect(exit_code).to eq(127)
        end
      end
    end

    describe '#remove' do
      it 'removes the specified version of Terraform' do
        test_versions.each do |semver|
          binary = subject[semver]
          expect(File.exist?(binary)).to be_truthy
          expect(subject.remove(semver)).to be_truthy
          expect(File.exist?(binary)).to be_falsey
        end
      end
    end
  end
end
