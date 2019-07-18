require 'spec_helper'

RSpec.describe Terradactyl::Terraform::VersionManager::Options do
  after(:each) do
    subject.reset!
  end

  let(:install_dir) do
    Terradactyl::Terraform::VersionManager::Options::DEFAULT_INSTALL_DIR
  end

  let(:downloads_url) do
    Terradactyl::Terraform::VersionManager::Options::DEFAULT_DOWNLOADS_URL
  end

  let(:releases_url) do
    Terradactyl::Terraform::VersionManager::Options::DEFAULT_RELEASES_URL
  end

  context 'simple initialization' do
    describe '#install_dir' do
      it 'returns the default value' do
        expect(subject.install_dir).to eq(install_dir)
      end
    end

    describe '#downloads_url' do
      it 'returns the default value' do
        expect(subject.downloads_url).to eq(downloads_url)
      end
    end

    describe '#releases_url' do
      it 'returns the default value' do
        expect(subject.releases_url).to eq(releases_url)
      end
    end
  end

  context 'post-init configuration' do
    before { @temp_dir = Dir.mktmpdir('terradactyl') }
    after  { FileUtils.rm_rf @temp_dir }

    describe '#install_dir=' do
      it 'sets the value' do
        subject.install_dir = @temp_dir
        expect(subject.install_dir).to eq(@temp_dir)
      end
    end
  end

  context 'provides nil-safe defaults' do
    describe '#install_dir=' do
      it 'ignores empty values' do
        subject.install_dir = ''
        expect(subject.install_dir).to eq(install_dir)
      end
      it 'ignores nil values' do
        subject.install_dir = nil
        expect(subject.install_dir).to eq(install_dir)
      end
      it 'ignores invalid path values' do
        subject.install_dir = 'some/fake/path'
        expect(subject.install_dir).to eq(install_dir)
      end
      it 'expands valid path values' do
        subject.install_dir = '~/'
        expect(subject.install_dir).not_to eq('~/')
        expect(subject.install_dir).to eq(File.expand_path('~/'))
      end
    end

    describe '#downloads_url=' do
      it 'ignores empty values' do
        subject.downloads_url = ''
        expect(subject.downloads_url).to eq(downloads_url)
      end
      it 'ignores nil values' do
        subject.downloads_url = nil
        expect(subject.downloads_url).to eq(downloads_url)
      end
      it 'ignores invalid url values' do
        subject.downloads_url = 'some/garbage/path'
        expect(subject.downloads_url).to eq(downloads_url)
      end
    end

    describe '#releases_url=' do
      it 'ignores empty values' do
        subject.releases_url = ''
        expect(subject.releases_url).to eq(releases_url)
      end
      it 'ignores nil values' do
        subject.releases_url = nil
        expect(subject.releases_url).to eq(releases_url)
      end
      it 'ignores invalid url values' do
        subject.releases_url = 'some/garbage/path'
        expect(subject.releases_url).to eq(releases_url)
      end
    end
  end
end
