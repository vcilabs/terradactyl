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
            auto_approve: true
        environment:
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
      puts "inside ConfigApplication initialize. arguments - config_file: #{config_file}, defaults: #{defaults}"

      @config_file = config_file
      @defaults    = load_defaults(defaults)
      @overlay     = load_overlay(config_file)
      load_config

      # binding.pry
    end

    def reload
      load_config
    end

    def to_h
      @config
    end
    alias to_hash to_h

    private

    def load_config(defaults_override: nil, overlay_override: nil)
      @config = [
        defaults_override || @defaults,
        overlay_override || @overlay
      ].inject({}) do |memo, obj|
        memo.deep_merge!(obj, overwrite_arrays: true)
        Marshal.load(Marshal.dump(memo))
      end
      @terradactyl = structify(@config).terradactyl

      puts "inside ConfigApplication load_config. @terradactyl.to_s:"
      puts @terradactyl.to_s # this is the contents of terradactyl.yaml

      configure_colorization
      @terradactyl
    end

    def load_defaults(defaults)
      defaults || YAML.safe_load(CONFIG_DEFAULTS)
    end

    def load_overlay(config_file)
      puts "inside ConfigApplication (OG) load_overlay. config_file: #{config_file} #{config_file.to_s}"

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
      puts "inside ConfigProject load_overlay. overload arg: #{_overload}, ref'd config_file: #{config_file}"

      config_file_path = _overload ? "./#{_overload}/#{config_file}" : config_file
      puts "config_file_path: #{config_file_path}"

      YAML.load_file(config_file_path)
    rescue Errno::ENOENT => e
      abort "FATAL: Could not load project file: `#{config_file}`, #{e.message}"
    end

    def config_file
      # puts "inside ConfigProject config_file def. What THE FUCK is the point of this shit"
      @config_file = CONFIG_PROJECT_FILE
    end

    def merge_overlay(overlay_path)
      puts "inside ConfigProject merge_overlay. overload arg: #{overlay_path}, ref'd config_file: #{config_file}"

      config_file_path = overlay_path ? "./#{overlay_path}/#{config_file}" : config_file
      puts "config_file_path: #{config_file_path}"

      config_to_merge = YAML.load_file(config_file_path)
      puts "config to merge #{config_to_merge}"

      # set base_folder name if it's '.'
      if config_to_merge['terradactyl']['base_folder'] == "." then
        puts "relative base folder"
        config_to_merge['terradactyl']['base_folder'] = overlay_path
        puts "UPDATED config to merge #{config_to_merge}"
      end

      load_config(overlay_override: config_to_merge)
    rescue Errno::ENOENT => e
      abort "FATAL: Could not load project file: `#{config_file}`, #{e.message}"
    end
  end

  class ConfigStack < ConfigApplication
    TERRAFORM_SETTINGS_FILES = %w[
      settings.tf
      versions.tf
      backend.tf
    ].freeze

    attr_reader :stack_name, :stack_path, :base_folder

    def initialize(stack_name, base_override="")
      puts "ConfigStack initialize, stack_name arg: #{stack_name}, base_override arg: #{base_override}"
      
      @stack_name     = stack_name
      @project_config = ConfigProject.instance
      @base_folder    = @project_config.base_folder # might change if base_override provided
      @stack_path     = "#{@base_folder}/#{@stack_name}"
      @config_file    = "#{@stack_path}/#{ConfigProject::CONFIG_PROJECT_FILE}"
      @defaults       = load_defaults(@project_config.to_h)
      @overlay        = load_overlay(@config_file)
      
      puts "ConfigStack end of init, base_folder: #{@base_folder} stack_path: #{@stack_path} config_file: #{@config_file}"

      load_config
    end

    alias name stack_name
    alias path stack_path

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

    def versions_file
      "#{stack_path}/versions.tf"
    end

    private

    def terraform_required_version
      matches = TERRAFORM_SETTINGS_FILES.each_with_object([]) do |file, memo|
        path = File.join(stack_path, file)
        next unless File.exist?(path)

        File.readlines(path).each do |line|
          next if line =~ /(?:\s*#\s*)/

          if (match = line.match(Common.required_versions_re))
            memo << match
          end
        end
      end

      return {} unless matches.any?

      {
        'terradactyl' => {
          'terraform' => {
            'version' => matches.last[:value].delete('"')
          }
        }
      }
    end

    def load_overlay(config_file)
      puts "inside ConfigStack load_overlay"
      overlay = super(config_file)

      puts "ConfigStack arg config_file: #{config_file}, overlay: #{overlay}"

      # TODO: do additional condition overlay if base_override is provided

      unless overlay_specifies_version?(overlay)
        puts "inside conditional block #{terraform_required_version}"
        overlay.merge!(terraform_required_version)
      end

      overlay
    end

    def overlay_specifies_version?(overlay)
      overlay['terradactyl']&.fetch('terraform', {})&.fetch('version', nil)
    end
  end
end
