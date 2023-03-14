# frozen_string_literal: true

module Terradactyl
  module Terraform
    module Subcommands
      module Upgrade
        def defaults
          {
            'yes' => false
          }
        end

        def switches
          %w[
            yes
          ]
        end
      end
    end

    module Commands
      class Upgrade < Base
        def execute
          VersionManager.install
          return 0 unless revision.upgradeable?

          super
        end

        def next_version
          @next_version ||= compute_upgrade
        end

        private

        def revision
          Terradactyl::Stack.revision
        end

        def compute_upgrade
          maj, min, _rev = version.split('.')
          resolution = VersionManager.resolve("~> #{maj}.#{min.to_i + 1}.0")
          VersionManager.version = resolution
          VersionManager.version
        end

        def subcmd
          pre = version.slice(/\d+\.\d+/)
          sig = self.class.name.split('::').last.downcase
          sig == 'base' ? '' : "#{pre}#{sig}"
        end
      end
    end
  end

  # rubocop:disable Metrics/ModuleLength
  module Commands
    class << self
      def extend_by_revision(tf_version, object)
        anon_module = revision_module
        revision    = revision_constant(tf_version)

        anon_module.include(self)
        anon_module.prepend(revision)

        object.class.define_singleton_method(:revision) { revision }
        object.define_singleton_method(:revision) { revision }

        object.extend(anon_module)
      end

      private

      def revision_module
        Module.new do
          class << self
            def extended(base)
              terraform_methods.each { |method| decorate(base, method) }
            end

            def decorate(base, method)
              base.define_singleton_method(method) do |*args, &block|
                setup_terraform
                pushd(stack_path)
                super(*args, &block)
              ensure
                popd
              end
            end

            private

            def terraform_methods
              public_instance_methods.reject { |m| m == :terraform_methods }
            end
          end
        end
      end

      def revision_constant(tf_version)
        revision = Terradactyl::Terraform.calc_revision(tf_version)
        const_get(revision)
      end
    end

    include Terraform::Commands

    def init
      Init.execute(dir_or_plan: nil, options: command_options)
    end

    def plan
      options = command_options.tap do |dat|
        dat.state    = state_file
        dat.out      = plan_file
        dat.no_color = true
      end

      captured = Plan.execute(dir_or_plan: nil,
                              options: options,
                              capture: true)

      @plan_file_obj = load_plan_file

      case captured.exitstatus
      when 0
        'No changes. Infrastructure is up-to-date.'
      when 1
        @plan_file_obj.error_output = captured.stderr
      when 2
        @plan_file_obj.plan_output = captured.stdout
        @plan_file_obj.save
      end

      captured.exitstatus
    end

    def apply
      Apply.execute(dir_or_plan: plan_file, options: command_options)
    end

    def refresh
      options = command_options.tap { |dat| dat.state = state_file }
      Refresh.execute(dir_or_plan: nil, options: options)
    end

    def destroy
      options = command_options.tap { |dat| dat.state = state_file }
      Destroy.execute(dir_or_plan: nil, options: options)
    end

    def lint
      options = command_options.tap { |dat| dat.check = true }
      Fmt.execute(dir_or_plan: nil, options: options)
    end

    def fmt
      Fmt.execute(dir_or_plan: nil, options: command_options)
    end

    def validate
      Validate.execute(dir_or_plan: nil, options: command_options)
    end

    # rubocop:disable Metrics/AbcSize
    def clean
      removals = config.cleanup.match.map { |p| Dir.glob("**/#{p}") }
      removals << `find . -type d -empty`.split if config.cleanup.empty
      removals = removals.flatten.sort.uniq.each do |trash|
        print_dot("Removing: #{trash}", :light_yellow)
        FileUtils.rm_rf(trash)
      end
      puts unless removals.empty?
    end
    # rubocop:enable Metrics/AbcSize

    def upgrade
      perform_upgrade
    end

    private

    def versions_file
      'versions.tf'
    end

    def settings_files
      Dir.glob('*.tf').each_with_object([]) do |file, memo|
        File.open(file, 'r').each_line do |line|
          if line.match(Common.required_versions_re)
            memo << file
            break
          end
        end
      end
    end

    def sanitize_terraform_settings
      settings_files.each do |file|
        next if file == versions_file

        write_stream = Tempfile.new(Common.tag)
        File.open(file, 'r').each_line do |line|
          write_stream.puts line unless line.match(Common.required_versions_re)
        end
        write_stream.close
        FileUtils.mv(write_stream.path, file)
      end
    end

    def update_required_version(upgrade_version)
      if File.exist?(versions_file)
        settings = File.read(versions_file)
        if (req_version = settings.match(Common.required_versions_re))
          substitution = %(#{req_version[:assignment]}"~> #{upgrade_version}")
          settings.sub!(Common.required_versions_re, substitution)
        end
      else
        # This is ugly, so let's explain ...
        #
        # When the versions.tf is present, but the stack is ~> 0.11.0, the
        # `terraform 0.12upgrade` subcommand will FAIL because it uses the
        # presence of this file as the sole gauge as to whether or not
        # the stack can be upgraded. So, why not just use `-force`? Haha yes ...
        #
        # When the `versions.tf` file exists and the `-force` flag is passed,
        # it will create a `versions-1.tf` file ... FML :facepalm:
        #
        # So, make the creation of a de facto versions.tf contingent upon the
        # Terraform upgrade_version. Yay.
        unless upgrade_version =~ /0\.12/
          settings = <<~VERSIONS
            terraform {
              required_version = "~> #{upgrade_version}"
            }
          VERSIONS
        end
      end

      File.write(versions_file, settings) if settings
    end

    def upgrade_notice
      output = File.read('versions.tf')
      insert = output.strip.split("\n").map { |l| "    #{l}" }.join($INPUT_RECORD_SEPARATOR)

      <<~NOTICE
        This stack has been upgraded to version the described below and its
        Terradactly config file (if it existed) has been removed.

        #{insert}

        NOTES:

         • ALL Terraform version constraints are now specified in `versions.tf` using
          the `required_version` directive.

         • If your stack already contained one or more `required_version` directives,
          they have been consolidated into a single directive in `versions.tf`.

         • Terraform provider version contraints ARE NOT upgraded automatically. You
          will need to edit these MANUALLY.

         • Before proceeding. please perform a `terradactyl quickplan` on your stack
          to ensure the upgraded stack functions as intended.
      NOTICE
    end

    def upgrade_notice_rev013
      <<~NOTICE
        STOP UPGRADING!

              Upgrading from Terraform 0.12 to 0.13 requires an apply to be performed
              before continuing ...

              DO NOT attempt to upgrade any further without first committing the existing
              changes and seeing they are applied.

              See the documentation here if you require more infomation ...

              https://www.terraform.io/upgrade-guides/0-13.html
      NOTICE
    end

    # rubocop:disable  Metrics/AbcSize
    def perform_upgrade
      options = command_options.tap { |dat| dat.yes = true }
      upgrade = Upgrade.new(dir_or_plan: nil, options: options)

      sanitize_terraform_settings

      update_required_version(upgrade.next_version)

      if (result = upgrade.execute).zero?
        update_required_version(upgrade.next_version)
        FileUtils.rm_rf('terradactyl.yaml') if File.exist?('terradactyl.yaml')
      end

      print_content(upgrade_notice) if result.zero?

      print_crit(upgrade_notice_rev013) if upgrade.next_version =~ /0\.13/

      result
    end
    # rubocop:enable  Metrics/AbcSize

    def load_plan_file
      Terraform::PlanFile.new(plan_path: plan_file, parser: parser)
    end

    module Rev011
      class << self
        def upgradeable?
          true
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev011::PlanFileParser
      end
    end

    module Rev012
      class << self
        def upgradeable?
          true
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev012::PlanFileParser
      end
    end

    module Rev013
      class << self
        def upgradeable?
          false
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev013::PlanFileParser
      end
    end

    module Rev014
      class << self
        def upgradeable?
          false
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev014::PlanFileParser
      end
    end

    module Rev015
      class << self
        def upgradeable?
          false
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev015::PlanFileParser
      end
    end

    module Rev1_00
      class << self
        def upgradeable?
          false
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev1_00::PlanFileParser
      end
    end

    module Rev1_01
      class << self
        def upgradeable?
          false
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev1_01::PlanFileParser
      end
    end
    module Rev1_02
      class << self
        def upgradeable?
          false
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev1_02::PlanFileParser
      end
    end

    module Rev1_03
      class << self
        def upgradeable?
          false
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev1_03::PlanFileParser
      end
    end

    module Rev1_04
      class << self
        def upgradeable?
          false
        end
      end

      include Terraform::Commands

      private

      def parser
        Terraform::Rev1_04::PlanFileParser
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
