# frozen_string_literal: true

module Terradactyl
  module Commands
    class << self
      def extended(base)
        terraform_methods.each { |method| decorate(base, method) }
      end

      def extend_revision(tf_version, object)
        self.include(revision_module(tf_version).include(Terraform::Commands))
        object.extend(self)
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
        public_instance_methods.reject { |meth| meth == :terraform_methods }
      end

      def revision_module(tf_version)
        revision_name = ['Rev', *tf_version.split('.').take(2)].join
        const_get(revision_name)
      end
    end

    def init
      Init.execute(dir_or_plan: nil, options: command_options)
    end

    def plan
      options = command_options.tap do |dat|
        dat.state = state_file
        dat.out   = plan_file
      end
      Plan.execute(dir_or_plan: nil, options: options)
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

    def plan_file_obj
      Terraform::PlanFile.load(plan_file, options: command_options)
    end

    module Rev011
      def checklist
        Checklist.execute(dir_or_plan: nil, options: command_options)
      end
    end

    module Rev012
    end
  end
end
