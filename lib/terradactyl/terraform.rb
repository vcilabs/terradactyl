module Terradactyl

  class TerraformVersion

    class << self

      MIN_VERSION   = '0.9.0'
      ERROR_VERSION = 'Terraform version mismatch'
      ERROR_INSTALL = 'Terraform not installed'

      include Common

      def current
        raw = %x{terraform version}.match(tf_raw_semver_re)
        Gem::Version.new raw['version']
      rescue
        nil
      end

      def minimum
        Gem::Version.new MIN_VERSION
      end

      def required
        Gem::Version.new config.terraform.version
      end

      def installed?
        current
      end

      def seatbelt
        raise ERROR_INSTALL unless installed?
        raise ERROR_VERSION unless (current >= minimum)
        raise ERROR_VERSION unless (current == required)
      rescue => e
        abort <<-HODOR
*** Terraform Version Requirements: ***
Minimum:  #{minimum}
Required: #{required}
Current:  #{current}
Error:    #{e.message}
Check your Terradactyl `terraform.yml` and ensure that both the config
and your installed Terraform binary meet the requirements.
HODOR
      end

      private

      def tf_raw_semver_re
        /^Terraform\s+v(?<version>(\d+\.\d+\.\d+))/
      end

    end

  end

end
