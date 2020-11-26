# frozen_string_literal: true

module Terradactyl
  class ConfigApplication
    CONFIG_DEFAULTS = <<~CONFIG_DEFAULTS
      ---
      terradactyl:
        base_folder: stacks
        terraform:
          binary:
          version:
          autoinstall: true
          install_dir:
          echo: false
          quiet: true
          init:
            lock: false
            force_copy: true
          plan:
            lock: false
            parallelism: 5
            detailed_exitcode: true
          apply:
            parallelism: 5
          refresh:
            input: false
          destroy:
            parallelism: 5
            force: true
        environment:
          AWS_REGION: us-west-2
          TF_PLUGIN_CACHE_DIR: ~/.terraform.d/plugins
        misc:
          utf8: true
          disable_color: false
        cleanup:
          empty: true
          match:
            - "*.tfout"
            - "*.tflock"
            - "*.zip"
            - ".terraform"
    CONFIG_DEFAULTS

    attr_reader :config_file, :terradactyl

    def initialize(config_file = nil, defaults: nil)
      @config_file = config_file
      @defaults    = load_defaults(defaults)
      @overlay     = load_overlay(config_file)
      load_config
    end

    def reload
      load_config
    end

    def to_h
      @config
    end
    alias_method :to_hash, :to_h

    private

    def load_config
      @config = [
        @defaults,
        @overlay
      ].inject({}) do |memo, obj|
        memo.deep_merge!(obj, overwrite_arrays: true)
        Marshal.load(Marshal.dump(memo))
      end
      @terradactyl = structify(@config).terradactyl
      configure_colorization
      @terradactyl
    end

    def load_defaults(defaults)
      defaults || YAML.safe_load(CONFIG_DEFAULTS)
    end

    def load_overlay(config_file)
      YAML.load_file(config_file.to_s)
    rescue Errno::ENOENT
      load_empty
    end

    def load_empty
      { 'terradactyl' => {} }
    end

    def structify(hash)
      OpenStruct.new(hash.each_with_object({}) do |(key, val), memo|
        memo[key] = val.is_a?(Hash) ? structify(val) : val
      end)
    end

    def configure_colorization
      String.disable_colorization = terradactyl.misc.disable_color
    end

    def method_missing(sym, *args, &block)
      terradactyl.send(sym.to_sym, *args, &block)
    rescue NameError
      super
    end

    def respond_to_missing?(sym, *args)
      terradactyl.respond_to?(sym) || super
    end
  end

  class ConfigProject < ConfigApplication
    include Singleton

    CONFIG_PROJECT_FILE = 'terradactyl.yaml'

    def self.instance
      @instance ||= new
    end

    private_class_method :new

    def load_overlay(_overload)
      YAML.load_file(config_file)
    rescue Errno::ENOENT => e
      abort "FATAL: Could not load project file: `#{config_file}`, #{e.message}"
    end

    def config_file
      @config_file = CONFIG_PROJECT_FILE
    end
  end

  class ConfigStack < ConfigApplication
    attr_reader :stack_name, :stack_path, :base_folder

    def initialize(stack_name)
      @stack_name     = stack_name
      @project_config = ConfigProject.instance
      @base_folder    = @project_config.base_folder
      @stack_path     = "#{@base_folder}/#{@stack_name}"
      @config_file    = "#{@stack_path}/#{ConfigProject::CONFIG_PROJECT_FILE}"
      @defaults       = load_defaults(@project_config.to_h)
      @overlay        = load_overlay(@config_file)
      load_config
    end

    alias_method :name, :stack_name
    alias_method :path, :stack_path

    def state_file
      'terraform.tfstate'
    end

    def state_path
      "#{stack_path}/terraform.tfstate"
    end

    def plan_file
      "#{stack_name}.tfout"
    end

    def plan_path
      "#{stack_path}/#{plan_file}"
    end
  end
end
