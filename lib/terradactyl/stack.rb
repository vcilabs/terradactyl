# frozen_string_literal: true

module Terradactyl
  class Stack
    include Common

    attr_reader :stack_config

    def self.load(stack_name)
      new(stack_name)
    end

    def initialize(stack_name)
      @stack_name   = validate_stack_name(stack_name)
      @stack_config = ConfigStack.new(@stack_name)
      @tf_version   = tf_version
      Commands.extend_by_revision(@tf_version, self)
      print_message "Terraform version: #{@tf_version}"
      inject_env_vars
    rescue NameError
      print_crit "Unsupported Terraform version: #{@tf_version}"
      Stacks.error!(stack_name)
      throw :error
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

    def planned?
      File.exist?(plan_path)
    end

    def remove_plan_file
      print_dot("Removing Plan File: #{plan_file}", :light_yellow)
      FileUtils.rm_rf(plan_path)
    end

    def print_plan
      print_content(plan_file_obj.plan_output)
    end

    def plan_file_obj
      @plan_file_obj ||= load_plan_file
    end

    private

    def autoinstall?
      config.terraform.autoinstall
    end

    def tf_version
      Terraform::VersionManager.resolve(config.terraform.version)
    rescue Terraform::VersionManager::VersionManagerError
      Terraform::VersionManager.latest
    end

    def setup_terraform
      %i[install_dir downloads_url releases_url].each do |opt|
        Terraform::VersionManager.send("#{opt}=".to_sym,
                                       config.terraform.send(opt))
      end

      Terraform::VersionManager.version = @tf_version
      Terraform::VersionManager.install if autoinstall?
    end

    def validate_stack_name(stack_name)
      klass = self.class.to_s.split('::').last
      unless (valid_name = Stacks.validate(stack_name))
        print_crit("#{klass} not found: #{File.basename(stack_name)}")
        abort
      end
      valid_name
    end

    def inject_env_vars
      return unless config.misc.disable_color

      args = ENV['TF_CLI_ARGS'].to_s.split(',')
      args << '-no-color'
      ENV['TF_CLI_ARGS'] = args.compact.flatten.uniq.join(',')
    end

    # rubocop:disable Metrics/AbcSize
    def command_options
      subcmd = caller_locations(1, 1)[0].label.to_sym
      Terraform::Commands::Options.new do |dat|
        dat.environment = config.environment
        dat.echo        = config.terraform.echo
        dat.quiet       = config.terraform.quiet
        config.terraform.send(subcmd)&.each_pair do |key, value|
          dat.send("#{key}=".to_sym, value)
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

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
