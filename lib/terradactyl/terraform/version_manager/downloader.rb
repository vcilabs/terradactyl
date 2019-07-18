# frozen_string_literal: true

module Terradactyl
  module Terraform
    module VersionManager
      class Downloader
        attr_accessor :url
        attr_reader :fh

        def self.fetch(url)
          new.fetch(url: url)
        end

        def initialize(url: nil)
          @url = url
        end

        def fetch(url: self.url)
          @fh   = URI.parse(url).open
          @path = @fh.path
          @fh
        end

        def checksum
          Digest::SHA256.file(path).hexdigest
        end

        def path
          @fh.path
        rescue NameError
          nil
        end

        def delete
          if @fh
            @fh.close
            @fh.unlink
          end
        end
      end
    end
  end
end
