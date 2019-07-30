# frozen_string_literal: true

module Terradactyl

  class Stack

    include Common
    include Terraform

    attr_reader :stack_config

    def initialize(stack_name)
      @stack_name   = validate_stack_name(stack_name)
      @stack_config = ConfigStack.new(@stack_name)
      inject_env_vars
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
      pushd(stack_path)
      Commands::Init.execute(dir_or_plan: nil, options: command_options)
    ensure
      popd
    end

    def plan
      pushd(stack_path)
      options = command_options.tap do |dat|
        dat.state = state_file
        dat.out   = plan_file
      end
      Commands::Plan.execute(dir_or_plan: nil, options: options)
    ensure
      popd
    end

    def apply
      pushd(stack_path)
      Commands::Apply.execute(dir_or_plan: plan_file, options: command_options)
    ensure
      popd
    end

    def refresh
      pushd(stack_path)
      options = command_options.tap { |dat| dat.state = state_file }
      Commands::Refresh.execute(dir_or_plan: nil, options: options)
    ensure
      popd
    end

    def destroy
      pushd(stack_path)
      options = command_options.tap { |dat| dat.state = state_file }
      Commands::Destroy.execute(dir_or_plan: nil, options: options)
    ensure
      popd
    end

    def lint
      pushd(stack_path)
      options = command_options.tap { |dat| dat.check = true }
      Commands::Fmt.execute(dir_or_plan: nil, options: options)
    ensure
      popd
    end

    def fmt
      pushd(stack_path)
      Commands::Fmt.execute(dir_or_plan: nil, options: command_options)
    ensure
      popd
    end

    def clean
      pushd(path)
      removals = config.cleanup.match.map { |p| Dir.glob("**/#{p}") }
      removals << %x(find . -type d -empty).split if config.cleanup.empty
      removals = removals.flatten.sort.uniq.each do |trash|
        print_dot("Removing: #{trash}", :light_yellow)
        FileUtils.rm_rf(trash)
      end
      puts unless removals.empty?
    ensure
      popd
    end

    def plan_file_obj
      Terraform::PlanFile.load(plan_path, options: command_options)
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

    def validate_stack_name(stack_name)
      unless stack_name = Stacks.validate(stack_name)
        print_crit("Stack not found: #{stack_name}")
        abort
      end
      stack_name
    end

    def inject_env_vars
      if config.misc.disable_color
        args = ENV['TF_CLI_ARGS'].to_s.split(',')
        args << '-no-color'
        ENV['TF_CLI_ARGS'] = args.compact.flatten.uniq.join(',')
      end
    end

    def command_options
      who = caller_locations(1, 1)[0].label.to_sym
      Commands::Options.new do |dat|
        dat.environment = config.environment
        %i[binary version autoinstall install_dir echo quiet].each do |key|
          dat.send("#{key}=".to_sym, config.terraform.send(key))
        end
        config.terraform.send(who)&.each_pair do |key, value|
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
