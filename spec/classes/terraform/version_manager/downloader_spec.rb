require 'spec_helper'

RSpec.describe Terradactyl::Terraform::VersionManager::Downloader do
  let(:url) { 'https://releases.hashicorp.com/terraform/0.12.2/terraform_0.12.2_darwin_amd64.zip' }

  describe '.fetch' do
    let(:downloader) { described_class.fetch(url) }
    it 'downloads a file and returns the file handle' do
      expect(downloader).to be_a(Tempfile)
      expect(File.exist?(downloader.path)).to be_truthy
      expect(downloader.read(2)).to eq('PK')
      expect(downloader.close).to be_nil
      expect(downloader.unlink).to be_truthy
    end
  end

  context 'with no arguments' do
    describe '#initialize' do
      it 'returns a downloader' do
        expect(subject).to be_a(Terradactyl::Terraform::VersionManager::Downloader)
      end

      it 'can set a url' do
        expect(subject.url = url).to eq(url)
      end
    end
  end

  context 'with arguments' do
    let(:downloader) { described_class.new(url: url) }

    describe '#initialize' do
      it 'returns a downloader' do
        expect(downloader).to be_a(Terradactyl::Terraform::VersionManager::Downloader)
      end

      it 'has a url' do
        expect(downloader.url).to eq(url)
      end
    end

    describe '#fetch' do
      let(:new_url) { 'https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_darwin_amd64.zip' }
      it 'fetches its url and returns a file handle' do
        downloader.url = new_url
        expect(downloader.fetch).to be_a(Tempfile)
      end
    end

    describe '#path' do
      it 'returns the path to the downloded file' do
        downloader.fetch
        expect(File.exist?(downloader.path)).to be_truthy
      end
    end

    describe '#delete' do
      it 'closes and unlinks the downloaded file' do
        downloader.fetch
        expect(downloader.delete).to be_truthy
        expect(File.exist?(downloader.path.to_s)).to be_falsey
      end
    end
  end
end
