require 'spec_helper'

RSpec.describe Terradactyl::Terraform::VersionManager::Package do
  let(:subject) { Object.new.extend(described_class) }

  describe '#architecture' do
    orig_arch = RbConfig::CONFIG['host_cpu']

    context 'on an unsupported CPU arch' do
      before { RbConfig::CONFIG['host_cpu'] = 'BAD_ARCH' }
      it 'raises an exception' do
        expect { subject.architecture }.to raise_error(RuntimeError, /FATAL: Unsupported CPU arch/)
      end
    end
    context 'on a supported CPU arch' do
      before { RbConfig::CONFIG['host_cpu'] = orig_arch }
      it 'return an appropriate value' do
        expect(subject.architecture).to match(/amd64|386|arm/)
      end
    end
  end

  describe '#platform' do
    orig_os = RbConfig::CONFIG['host_os']

    context 'on an unsupported Platform' do
      before { RbConfig::CONFIG['host_os'] = 'BAD_PLATFORM' }
      it 'raises an exception' do
        expect { subject.platform }.to raise_error(RuntimeError, /FATAL: Unsupported OS Platform/)
      end
    end
    context 'on a supported Platform' do
      before { RbConfig::CONFIG['host_os'] = orig_os }
      it 'return an appropriate value' do
        expect(subject.platform).to match(/darwin|freebsd|linux|openbsd|solaris|windows/)
      end
    end
  end

  describe '#downloads_url' do
    it 'returns the base URL for fetchable packages' do
      expect(subject.downloads_url).to eq(Terradactyl::Terraform::VersionManager.downloads_url)
    end
  end

  describe '#releases_url' do
    it 'returns the Terraform downloadlanding page URL' do
      expect(subject.releases_url).to eq(Terradactyl::Terraform::VersionManager.releases_url)
    end
  end
end
