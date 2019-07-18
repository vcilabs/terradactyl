# frozen_string_literal: true

module Terradactyl
  module Terraform
    module VersionManager
      class Binary
        include Package

        ERROR_CHECKSUM = 'FATAL: Calculated sum does not match published value!'

        attr_accessor :version

        def initialize(version: nil, downloader: nil)
          @version    = version || VersionManager.latest
          @downloader = downloader || Downloader.new
        end

        def install
          return install_path if installed?

          validate_checksum if fetch
          unzip(@downloader.path, install_path)
          FileUtils.chmod(0o755, install_path)
          install_path
        ensure
          cleanup
        end

        def remove
          return false unless installed?

          FileUtils.rm_f(install_path)
          install_path
        end

        def cleanup
          @downloader.delete
        end

        def install_path
          "#{VersionManager.install_dir}/#{install_file}"
        end

        def download
          @downloader.path.to_s
        end

        def installed?
          File.exist?(install_path)
        end

        private

        def unzip(src, dst)
          Zip::File.open(src) { |arch| arch.each { |f| f.extract(dst) } }
        end

        def fetch
          @download ||= @downloader.fetch(url: download_url)
        end

        def validate_checksum
          checksum = fetch_checksum
          raise ERROR_CHECKSUM unless checksum == @downloader.checksum
        end

        def fetch_checksum
          checksums[archive_file]
        end

        def checksums
          base  = "#{releases_url}/#{version}/terraform_#{version}_SHA256SUMS"
          strio = URI.parse(base).open
          strio.readlines.inject({}) do |memo, line|
            memo.merge!(Hash[*(line.split(/\s+/).reverse)])
          end
        end

        def install_file
          "terraform-#{version}"
        end

        def archive_file
          "terraform_#{version}_#{platform}_#{architecture}.zip"
        end

        def download_url
          "#{releases_url}/#{version}/#{archive_file}"
        end
      end
    end
  end
end
