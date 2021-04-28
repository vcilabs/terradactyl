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
      class UnsupportedCommandError < RuntimeError
        def initialize(msg)
          super(msg)
        end
      end

      class Upgrade < Base
        ERROR_UNSUPPORTED = <<~ERROR
          subcommand `upgrade` is not supported on this stack!

                This stack may already be upgraded. Check the stack's specified
                Terraform version and consult its builtin help for further
                details.
        ERROR

        class << self
          def error_unsupported
            raise UnsupportedCommandError, ERROR_UNSUPPORTED
          end
        end

        def version
          @version ||= calculate_upgrade(super)
        end

        private

        def calculate_upgrade(current_version)
          maj, min, _rev = current_version.split('.')
          min = min.to_i < 13 ? (min.to_i + 1) : min
          resolution = VersionManager.resolve("~> #{maj}.#{min}.0")
          VersionManager.version = resolution
          VersionManager.install
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

        anon_module.include(self)
        anon_module.prepend(revision_constant(tf_version))

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
        revision_name = ['Rev', *tf_version.split('.').take(2)].join
        const_get(revision_name)
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
      Upgrade.error_unsupported
    end

    private

    def settings_files
      Terradactyl::ConfigStack::TERRAFORM_SETTINGS_FILES.select do |file|
        File.exist?(file)
      end
    end

    def update_required_version(upgrade_version)
      replace_me = /(?<assignment>(?:\n\s)*required_version\s+=\s+)(?<value>".*?")/m

      settings_files.each do |file|
        settings     = File.read(file)
        substitution = nil.to_s

        if (req_version = settings.match(replace_me))
          if file == 'versions.tf'
            substitution = %(#{req_version[:assignment]}"~> #{upgrade_version}")
          end
        end

        settings.sub!(replace_me, substitution)

        File.write(file, settings)
      end
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

         • If your stack already containedo one or more `required_version` directives,
          they have been consolidated into a single directive in `versions.tf`.

         • Terraform provider version contraints ARE NOT upgraded automatically. You
          will need to edit these MANUALLY.

         • Before proceeding. please perform a `terradactyl quickplan` on your stack
          to ensure the upgraded stack functions.
      NOTICE
    end

    def perform_upgrade
      options = command_options.tap { |dat| dat.yes = true }
      upgrade = Upgrade.new(dir_or_plan: nil, options: options)

      update_required_version(upgrade.version)

      if (result = upgrade.execute).zero?
        update_required_version(upgrade.version)
        FileUtils.rm_rf('terradactyl.yaml') if File.exist?('terradactyl.yaml')
      end

      print_content(upgrade_notice)

      result
    end

    def load_plan_file
      Terraform::PlanFile.new(plan_path: plan_file, parser: parser)
    end

    module Rev011
      include Terraform::Commands

      def upgrade
        perform_upgrade
      end

      private

      def parser
        Terraform::Rev011::PlanFileParser
      end
    end

    module Rev012
      include Terraform::Commands

      def upgrade
        perform_upgrade
      end

      private

      def parser
        Terraform::Rev012::PlanFileParser
      end
    end

    module Rev013
      include Terraform::Commands

      def upgrade
        perform_upgrade
      end

      private

      def parser
        Terraform::Rev013::PlanFileParser
      end
    end

    module Rev014
      include Terraform::Commands

      private

      def parser
        Terraform::Rev014::PlanFileParser
      end
    end

    module Rev015
      include Terraform::Commands

      private

      def parser
        Terraform::Rev015::PlanFileParser
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
