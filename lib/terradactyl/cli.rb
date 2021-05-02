# frozen_string_literal: true

# Fix for https://github.com/erikhuda/thor/issues/398
class Thor
  module Shell
    class Basic
      def print_wrapped(message, options = {})
        indent = (options[:indent] || 0).to_i
        if indent.zero?
          stdout.puts message
        else
          message.each_line do |message_line|
            stdout.print ' ' * indent
            stdout.puts message_line.chomp
          end
        end
      end
    end
  end
end

module Terradactyl
  # rubocop:disable Metrics/ClassLength
  class CLI < Thor
    include Common
    def self.exit_on_failure?
      true
    end

    def initialize(*args)
      # Hook ensures abort on stack errors
      at_exit { abort if Stacks.error? }
      super
    end

    # rubocop:disable Metrics/BlockLength
    no_commands do
      # Monkey-patch Thor internal method to break out of nested calls
      def invoke_command(command, *args)
        catch(:error) { super }
      end

      def validate_smartplan(stacks)
        if stacks.empty?
          print_message 'No Stacks Modified ...'
          print_line 'Did you forget to `git add` your selected changes?'
        end
        stacks
      end

      def validate_planpr(stacks)
        if stacks.empty?
          print_message 'No Stacks Modified ...'
          print_line 'Skipping plan ...'
        end
        stacks
      end

      def generate_report(report)
        data_file = "#{config.base_folder}.audit.json"
        print_warning "Writing Report: #{data_file} ..."
        report[:error] = Stacks.error.map { |s| "#{config.base_folder}/#{s.name}" }.sort
        File.write data_file, JSON.pretty_generate(report)
        print_ok 'Done!'
      end

      def terraform_latest
        Terradactyl::Terraform::VersionManager.latest
      end

      def upgrade_stack(name)
        @stack ||= Stack.new(name)
        print_warning "Upgrading: #{@stack.name}"
        if @stack.upgrade.zero?
          print_ok "Upgraded: #{@stack.name}"
        else
          Stacks.error!(@stack)
          print_crit "Failed to upgrade: #{@stack.name}"
          throw :error
        end
      rescue Terradactyl::Terraform::VersionManager::VersionManagerError => e
        print_crit "Error: #{e.message}"
        exit 1
      end
    end
    # rubocop:enable Metrics/BlockLength

    #################################################################
    # GENERIC TASKS
    # * These tasks are used regularly against stacks, by name.
    #################################################################

    desc 'defaults', 'Print the compiled configuration'
    def defaults
      puts config.to_h.to_yaml
    end

    desc 'stacks', 'List the stacks'
    def stacks
      print_ok 'Stacks:'
      Stacks.load.each do |name|
        print_dot name.to_s
      end
    end

    desc 'version', 'Print version'
    def version
      print_message format('version: %<semver>s', semver: Terradactyl::VERSION)
    end

    #################################################################
    # SPECIAL TASKS
    # * These tasks are related to Git state and PR planning ops.
    # * Some are useful only in pipelines. These are hidden.
    #################################################################

    desc 'planpr', 'Plan stacks against origin/HEAD (used for PRs)', hide: true
    def planpr
      print_header 'SmartPlanning PR ...'
      stacks = Stacks.load(filter: StacksPlanFilterGitDiffOriginBranch.new)
      validate_planpr(stacks).each do |name|
        clean(name)
        init(name)
        plan(name)
        @stack = nil
      end
    end

    desc 'smartplan', 'Plan any stacks that differ from Git HEAD'
    def smartplan
      print_header 'SmartPlanning Stacks ...'
      stacks = Stacks.load(filter: StacksPlanFilterGitDiffHead.new)
      validate_smartplan(stacks).each do |name|
        clean(name)
        init(name)
        plan(name)
        @stack = nil
      end
    end

    desc 'smartapply', 'Apply any stacks that contain plan files', hide: true
    def smartapply
      print_header 'SmartApplying Stacks ...'
      stacks = Stacks.load(filter: StacksApplyFilterPrePlanned.new)
      print_warning 'No stacks contain plan files ...' unless stacks.any?
      stacks.each do |name|
        apply(name)
        @stack = nil
      end
      print_message "Total Stacks Modified: #{stacks.size}"
    end

    desc 'smartrefresh', 'Refresh any stacks that contain plan files', hide: true
    def smartrefresh
      print_header 'SmartRefreshing Stacks ...'
      stacks = Stacks.load(filter: StacksApplyFilterPrePlanned.new)
      print_warning 'No stacks contain plan files ...' unless stacks.any?
      stacks.each do |name|
        refresh(name)
        @stack = nil
      end
      print_message "Total Stacks Refreshed: #{stacks.size}"
    end

    #################################################################
    # META-STACK TASKS
    # * These tasks are used regularly against groups of stacks, but
    # the `quickplan` task is an exception to this rule.
    #################################################################

    desc 'upgrade NAME', 'Cleans, inits, upgrades and formats an individual stack, by name'
    def upgrade(name)
      clean(name)
      init(name, backend: false)
      upgrade_stack(name)
      fmt(name)
    end

    desc 'quickplan NAME', 'Clean, init and plan a stack, by name'
    def quickplan(name)
      print_header "Quick planning #{name} ..."
      clean(name)
      init(name)
      plan(name)
    end

    desc 'clean-all', 'Clean all stacks'
    def clean_all
      print_header 'Cleaning ALL Stacks ...'
      Stacks.load.each do |name|
        clean(name)
        @stack = nil
      end
    end

    desc 'plan-all', 'Plan all stacks'
    def plan_all
      print_header 'Planning ALL Stacks ...'
      Stacks.load.each do |name|
        catch(:error) do
          clean(name)
          init(name)
          plan(name)
        end
        @stack = nil
      end
    end

    desc 'audit-all', 'Audit all stacks'
    options report: :optional
    method_option :report, type: :boolean
    # rubocop:disable Metrics/AbcSize
    def audit_all
      report = { start: Time.now.to_json }
      print_header 'Auditing ALL Stacks ...'
      Stacks.load.each do |name|
        catch(:error) do
          clean(name)
          init(name)
          audit(name)
        end
        @stack = nil
      end
      report[:finish] = Time.now.to_json
      if options[:report]
        print_header 'Audit Report ...'
        generate_report(report)
      end
    end
    # rubocop:enable Metrics/AbcSize

    desc 'validate-all', 'Validate all stacks'
    def validate_all
      print_header 'Validating ALL Stacks ...'
      Stacks.load.each do |name|
        catch(:error) do
          clean(name)
          init(name)
          validate(name)
        end
        @stack = nil
      end
    end

    #################################################################
    # TARGETED STACK TASKS
    # * These tasks are used regularly against stacks, by name.
    #################################################################

    desc 'lint NAME', 'Lint an individual stack, by name'
    def lint(name)
      @stack ||= Stack.new(name)
      print_ok "Linting: #{@stack.name}"
      if @stack.lint.zero?
        print_ok "Formatting OK: #{@stack.name}"
      else
        Stacks.error!(@stack)
        print_warning "Bad Formatting: #{@stack.name}"
      end
    end

    desc 'fmt NAME', 'Format an individual stack, by name'
    def fmt(name)
      @stack ||= Stack.new(name)
      print_warning "Formatting: #{@stack.name}"
      if @stack.fmt.zero?
        print_ok "Formatted: #{@stack.name}"
      else
        Stacks.error!(@stack)
        print_crit "Formatting failed: #{@stack.name}"
      end
    end

    desc 'init NAME', 'Init an individual stack, by name'
    def init(name, backend: true)
      @stack ||= Stack.new(name)
      @stack.config.terraform.init.backend = backend

      print_ok "Initializing: #{@stack.name}"
      if @stack.init.zero?
        print_ok "Initialized: #{@stack.name}"
      else
        Stacks.error!(@stack)
        print_crit "Initialization failed: #{@stack.name}"
        throw :error
      end
    end

    desc 'plan NAME', 'Plan an individual stack, by name'
    # rubocop:disable Metrics/AbcSize
    def plan(name)
      @stack ||= Stack.new(name)
      print_ok "Planning: #{@stack.name}"
      case @stack.plan
      when 0
        print_ok "No changes: #{@stack.name}"
      when 1
        Stacks.error!(@stack)
        print_crit "Plan failed: #{@stack.name}"
        @stack.print_error
        throw :error
      when 2
        Stacks.dirty!(@stack)
        print_warning "Changes detected: #{@stack.name}"
        @stack.print_plan
      else
        raise
      end
    end
    # rubocop:enable Metrics/AbcSize

    desc 'audit NAME', 'Audit an individual stack, by name'
    def audit(name)
      plan(name)
      if (@stack = Stacks.dirty?(name))
        Stacks.error!(@stack)
        print_crit "Dirty stack: #{@stack.name}"
      end
    end

    desc 'validate NAME', 'Validate an individual stack, by name'
    def validate(name)
      @stack ||= Stack.new(name)
      print_ok "Validating: #{@stack.name}"
      if @stack.validate.zero?
        print_ok "Validated: #{@stack.name}"
      else
        Stacks.error!(@stack)
        print_crit "Validation failed: #{@stack.name}"
        throw :error
      end
    end

    desc 'clean NAME', 'Clean an individual stack, by name'
    def clean(name)
      @stack ||= Stack.new(name)
      print_warning "Cleaning: #{@stack.name}"
      @stack.clean
      print_ok "Cleaned: #{@stack.name}"
    end

    desc 'apply NAME', 'Apply an individual stack, by name'
    def apply(name)
      @stack ||= Stack.new(name)
      print_warning "Applying: #{@stack.name}"
      if @stack.apply.zero?
        print_ok "Applied: #{@stack.name}"
      else
        Stacks.error!(@stack)
        print_crit "Failed to apply changes: #{@stack.name}"
      end
    end

    desc 'refresh NAME', 'Refresh state on an individual stack, by name'
    def refresh(name)
      @stack ||= Stack.new(name)
      print_crit "Refreshing: #{@stack.name}"
      if @stack.refresh.zero?
        print_warning "Refreshed: #{@stack.name}"
      else
        Stacks.error!(@stack)
        print_crit "Failed to refresh stack: #{@stack.name}"
      end
    end

    desc 'destroy NAME', 'Destroy an individual stack, by name'
    def destroy(name)
      @stack ||= Stack.new(name)
      print_crit "Destroying: #{@stack.name}"
      if @stack.destroy.zero?
        print_warning "Destroyed: #{@stack.name}"
      else
        Stacks.error!(@stack)
        print_crit "Failed to apply changes: #{@stack.name}"
      end
    end

    #################################################################
    # PROJECT-LEVEL UTILITY TASKS
    # * These tasks are managing project-wide characteristics or
    # invoking useful commands.
    #################################################################

    desc 'install COMPONENT', 'Installs specified component'
    long_desc <<~LONGDESC
      The `terradactyl install COMPONENT` subcommand perfoms installations of
      prerequisties. At present, only Terraform binaries are supported.

      Here are a few examples:

      # Install latest
      `terradactyl install terraform`

      # Install pessimistic version
      `terradactyl install terraform --version="~> 0.13.0"`

      # Install ranged version
      `terradactyl install terraform --version=">= 0.14.5, <= 0.14.7"`

      # Install explicit version
      `terradactyl install terraform --version=0.15.0-beta2`

    LONGDESC
    option :version, type: :string, default: 'latest'
    # rubocop:disable Metrics/AbcSize
    def install(component)
      case component.to_sym
      when :terraform
        print_warning "Installing: #{component}, version: #{options[:version]}"
        version = options[:version] == 'latest' ? terraform_latest : options[:version]
        Terradactyl::Terraform::VersionManager.reset!
        Terradactyl::Terraform::VersionManager.version = version
        Terradactyl::Terraform::VersionManager.install
        if Terradactyl::Terraform::VersionManager.binary
          print_ok "Installed: #{Terradactyl::Terraform::VersionManager.binary}"
        end
      else
        msg = %(Operation not supported -- I don't know how to install: #{component})
        print_crit msg
        exit 1
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
  # rubocop:enable Metrics/ClassLength
end
