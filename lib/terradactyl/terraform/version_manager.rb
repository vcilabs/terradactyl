# frozen_string_literal: true

require_relative 'version_manager/options'
require_relative 'version_manager/downloader'
require_relative 'version_manager/package'
require_relative 'version_manager/binary'

module Terradactyl
  module Terraform
    class VersionError < RuntimeError
      attr_reader :minimum, :current, :required

      def initialize(msg, minimum, required)
        @minimum  = minimum
        @required = required
        super(msg)
      end
    end

    module VersionManager
      class << self
        MIN_VERSION   = '0.11.10'
        ERROR_VERSION = 'Terraform version mismatch'
        ERROR_INSTALL = 'Terraform not installed'

        attr_writer :options

        def options
          @options ||= Options.new
          block_given? ? yield(@options) : @options
        end

        def latest
          calculate_latest
        end

        def install(version, type: Binary)
          package = type.new(version: version)
          package.install
        end

        def remove(version, type: Binary)
          package = type.new(version: version)
          package.remove
        end

        def seatbelt(semver)
          version_error(ERROR_INSTALL, semver) unless any?
          version_error(ERROR_VERSION, semver) unless minimum?
          version_error(ERROR_VERSION, semver) unless inventory(semver)
        end

        def list
          Dir.glob("#{install_dir}/terraform-*")
        end

        def inventory(semver = nil)
          @inventory = list.each_with_object({}) do |path, memo|
            match = File.basename(path).match(inventory_name_re)['version']
            memo[match] = path
          end
          semver ? @inventory[semver] : @inventory
        end

        def [](semver)
          inventory[semver]
        end

        def any?
          list.any?
        end

        def minimum?
          (inventory.select do |semver|
            Gem::Version.new(semver) >= Gem::Version.new(minimum)
          end).any?
        end

        def search
          list.first || 'terraform'
        end

        private

        def minimum
          MIN_VERSION
        end

        def version_error(msg, required)
          raise VersionError.new(msg, minimum, required)
        end

        def calculate_latest
          fh = Downloader.fetch(downloads_url)
          re = %r{#{releases_url}\/(?<version>\d+\.\d+\.\d+)}
          fh.read.match(re)['version']
        ensure
          fh.close
          fh.unlink
        end

        def inventory_name_re
          /(?:terraform-)(?<version>\d+\.\d+\.\d+)/
        end

        def method_missing(sym, *args, &block)
          options.send(sym.to_sym, *args, &block)
        rescue NameError
          super
        end

        def respond_to_missing?(sym, *args)
          options.respond_to?(sym) || super
        end
      end
    end
  end
end
