# frozen_string_literal: true

module Terradactyl
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

      output = case captured.exitstatus
               when 0
                 'No changes. Infrastructure is up-to-date.'
               when 1
                 captured.stderr
               when 2
                 captured.stdout
               end

      @plan_file_obj             = load_plan_file
      @plan_file_obj.plan_output = output
      @plan_file_obj.save

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

    def clean
      removals = config.cleanup.match.map { |p| Dir.glob("**/#{p}") }
      removals << `find . -type d -empty`.split if config.cleanup.empty
      removals = removals.flatten.sort.uniq.each do |trash|
        print_dot("Removing: #{trash}", :light_yellow)
        FileUtils.rm_rf(trash)
      end
      puts unless removals.empty?
    end

    private

    def load_plan_file
      Terraform::PlanFile.new(plan_path: plan_file, parser: parser)
    end

    module Rev011
      include Terraform::Commands

      def checklist
        Checklist.execute(dir_or_plan: nil, options: command_options)
      end

      private

      def parser
        Terraform::Rev011::PlanFileParser
      end
    end

    module Rev012
      include Terraform::Commands

      private

      def parser
        Terraform::Rev012::PlanFileParser
      end
    end

    module Rev013
      include Terraform::Commands

      private

      def parser
        Terraform::Rev012::PlanFileParser
      end
    end
  end
end
