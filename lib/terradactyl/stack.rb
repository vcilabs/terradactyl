# frozen_string_literal: true

module Terradactyl
  class Stack
    include Common
    include Terraform

    attr_reader :stack_config

    COMMANDS = %i[
      init
      plan
      apply
      refresh
      destroy
      lint
      fmt
      validate
      checklist
      clean
      plan_file_obj
    ].freeze

    def self.load(stack_name)
      new(stack_name)
    end

    def initialize(stack_name)
      @stack_name   = validate_stack_name(stack_name)
      @stack_config = ConfigStack.new(@stack_name)
      inject_env_vars
      decorate_cmds(*COMMANDS)
    end

    def config
      stack_config || super
    end

    def <=>(other)
      name <=> other.name
    end

    def to_s
      "<name: #{name}, path: #{path}>"
    end

    def init
      Commands::Init.execute(dir_or_plan: nil, options: command_options)
    end

    def plan
      options = command_options.tap do |dat|
        dat.state = state_file
        dat.out   = plan_file
      end
      Commands::Plan.execute(dir_or_plan: nil, options: options)
    end

    def apply
      Commands::Apply.execute(dir_or_plan: plan_file, options: command_options)
    end

    def refresh
      options = command_options.tap { |dat| dat.state = state_file }
      Commands::Refresh.execute(dir_or_plan: nil, options: options)
    end

    def destroy
      options = command_options.tap { |dat| dat.state = state_file }
      Commands::Destroy.execute(dir_or_plan: nil, options: options)
    end

    def lint
      options = command_options.tap { |dat| dat.check = true }
      Commands::Fmt.execute(dir_or_plan: nil, options: options)
    end

    def fmt
      Commands::Fmt.execute(dir_or_plan: nil, options: command_options)
    end

    def validate
      Commands::Validate.execute(dir_or_plan: nil, options: command_options)
    end

    def checklist
      Commands::Checklist.execute(dir_or_plan: nil, options: command_options)
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

    def planned?
      File.exist?(plan_path)
    end

    def remove_plan_file
      print_dot("Removing Plan File: #{plan_file}", :light_yellow)
      FileUtils.rm_rf(plan_path)
    end

    def show_plan_file
      print_content(plan_file_obj.to_s)
      print_content(plan_file_obj.summary)
    end

    private

    def decorate_cmds(*cmds)
      cmds.each do |meth|
        define_singleton_method(meth) do
          setup_terraform
          pushd(stack_path)
          super()
        ensure
          popd
        end
      end
    end

    def autoinstall?
      config.terraform.autoinstall
    end

    def setup_terraform
      %i[version install_dir downloads_url releases_url].each do |opt|
        VersionManager.send("#{opt}=".to_sym, config.terraform.send(opt))
      end
      VersionManager.install if autoinstall?
    end

    def validate_stack_name(stack_name)
      unless (stack_name = Stacks.validate(stack_name))
        print_crit("Stack not found: #{stack_name}")
        abort
      end
      stack_name
    end

    def inject_env_vars
      return unless config.misc.disable_color

      args = ENV['TF_CLI_ARGS'].to_s.split(',')
      args << '-no-color'
      ENV['TF_CLI_ARGS'] = args.compact.flatten.uniq.join(',')
    end

    def command_options
      subcmd = caller_locations(1, 1)[0].label.to_sym
      Commands::Options.new do |dat|
        dat.environment = config.environment
        dat.echo        = config.terraform.echo
        dat.quiet       = config.terraform.quiet
        config.terraform.send(subcmd)&.each_pair do |key, value|
          dat.send("#{key}=".to_sym, value)
        end
      end
    end

    def pushd(path)
      @working_dir_last = Dir.pwd
      Dir.chdir(path)
    end

    def popd
      Dir.chdir(@working_dir_last)
    end

    def method_missing(sym, *args, &block)
      config.send(sym.to_sym, *args, &block)
    rescue NameError
      super
    end

    def respond_to_missing?(sym, *args)
      config.respond_to?(sym) || super
    end
  end
end
