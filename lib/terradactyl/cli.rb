module Terradactyl

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

    no_commands {

      # Monkey-patch Thor internal method to break out of nested calls
      def invoke_command(command, *args)
        catch(:error) { super }
      end

      def validate_smartplan(stacks)
        if stacks.size == 0
          print_message "No Stacks Modified ..."
          print_line "Did you forget to `git add` your selected changes?"
        end
        stacks
      end

      def validate_planpr(stacks)
        if stacks.size == 0
          print_message "No Stacks Modified ..."
          print_line "Skipping plan ..."
        end
        stacks
      end

      def generate_report(report)
        data_file = "#{config.base_folder}.audit.json"
        print_warning "Writing Report: #{data_file} ..."
        report[:error] = Stacks.error.map { |s| "#{config.base_folder}/#{s.name}" }.sort
        File.write data_file, JSON.pretty_generate(report)
        print_ok "Done!"
      end

    }

    #################################################################
    # GENERIC TASKS
    # * These tasks are used regularly against stacks, by name.
    #################################################################

    desc 'stacks', 'List the stacks'
    def stacks
      print_ok "Stacks:"
      Stacks.load.each do |stack|
        print_dot "#{stack}"
      end
    end

    desc 'version', 'Print version'
    def version
      print_message "version: %s" % Terradactyl::VERSION
    end

    #################################################################
    # SPECIAL TASKS
    # * These tasks are related to Git state and PR planning ops.
    # * Some are useful only in pipelines. These are hidden.
    #################################################################

    desc 'planpr', 'Plan stacks against origin/HEAD (used for PRs)', hide: true
    def planpr
      print_header "SmartPlanning PR ..."
      stacks = Stacks.load(filter: StacksPlanFilterGitDiffOriginBranch.new)
      validate_planpr(stacks).each do |stack|
        clean(stack)
        init(stack)
        plan(stack)
      end
    end

    desc 'smartplan', 'Plan any stacks that differ from Git HEAD'
    def smartplan
      print_header "SmartPlanning Stacks ..."
      stacks = Stacks.load(filter: StacksPlanFilterGitDiffHead.new)
      validate_smartplan(stacks).each do |stack|
        clean(stack)
        init(stack)
        plan(stack)
      end
    end

    desc 'smartapply', 'Apply any stacks that contain plan files', hide: true
    def smartapply
      print_header "SmartApplying Stacks ..."
      stacks = Stacks.load(filter: StacksApplyFilterPrePlanned.new)
      print_warning 'No stacks contain plan files ...' unless stacks.any?
      stacks.each { |stack| apply(stack) }
      print_message "Total Stacks Modified: #{stacks.size}"
    end

    desc 'smartrefresh','Refresh any stacks that contain plan files', hide: true
    def smartrefresh
      print_header "SmartRefreshing Stacks ..."
      stacks = Stacks.load(filter: StacksApplyFilterPrePlanned.new)
      print_warning 'No stacks contain plan files ...' unless stacks.any?
      stacks.each { |stack| refresh(stack) }
      print_message "Total Stacks Refreshed: #{stacks.size}"
    end

    #################################################################
    # META-STACK TASKS
    # * These tasks are used regularly against groups of stacks, but
    # the `quickplan` task is an exception to this rule.
    #################################################################

    desc 'quickplan NAME', 'Clean, init and plan a stack, by name'
    def quickplan(name)
      print_header "Quick planning #{name} ..."
      clean(name)
      init(name)
      plan(name)
    end

    desc 'cleanall', 'Clean all stacks'
    def cleanall
      print_header "Cleaning ALL Stacks ..."
      Stacks.load.each { |stack| clean(stack) }
    end

    desc 'planall', 'Plan all stacks'
    def planall
      print_header "Planning ALL Stacks ..."
      Stacks.load.each do |stack|
        catch(:error) do
          clean(stack)
          init(stack)
          plan(stack)
        end
      end
    end

    desc 'auditall', 'Audit all stacks'
    options report: :optional
    method_option :report, :type => :boolean
    def auditall
      report = { start: Time.now.to_json }
      print_header "Auditing ALL Stacks ..."
      Stacks.load.each do |stack|
        catch(:error) do
          clean(stack)
          init(stack)
          audit(stack)
        end
      end
      report[:finish] = Time.now.to_json
      if options[:report]
        print_header "Audit Report ..."
        generate_report(report)
      end
    end

    #################################################################
    # TARGETED STACK TASKS
    # * These tasks are used regularly against stacks, by name.
    #################################################################

    desc 'lint NAME', 'Lint an individual stack, by name'
    def lint(name)
      stack = Stack.new(name)
      print_ok "Linting: #{stack.name}"
      if stack.lint.zero?
        print_ok "Formatting OK: #{stack.name}"
      else
        Stacks.error!(stack)
        print_warning "Bad Formatting: #{stack.name}"
      end
    end

    desc 'fmt NAME', 'Format an individual stack, by name'
    def fmt(name)
      stack = Stack.new(name)
      print_warning "Formatting: #{stack.name}"
      if stack.fmt.zero?
        print_ok "Formatted: #{stack.name}"
      else
        Stacks.error!(stack)
        print_crit "Formatting failed: #{stack.name}"
      end
    end

    desc 'init NAME', 'Init an individual stack, by name'
    def init(name)
      stack = Stack.new(name)
      print_ok "Initializing: #{stack.name}"
      if stack.init.zero?
        print_ok "Initialized: #{stack.name}"
      else
        Stacks.error!(stack)
        print_crit "Initialization failed: #{stack.name}"
        throw :error
      end
    end

    desc 'plan NAME', 'Plan an individual stack, by name'
    def plan(name)
      stack = Stack.new(name)
      print_ok "Planning: #{stack.name}"
      case stack.plan
      when 0
        print_ok "No changes: #{stack.name}"
      when 1
        Stacks.error!(stack)
        print_crit "Plan failed: #{stack.name}"
        throw :error
      when 2
        Stacks.dirty!(stack)
        print_warning "Changes detected: #{stack.name}"
        stack.show_plan_file
      else
        fail
      end
    end

    desc 'audit NAME', 'Audit an individual stack, by name'
    def audit(name)
      plan(name)
      if stack = Stacks.dirty?(name)
        Stacks.error!(stack)
        print_crit "Dirty stack: #{stack.name}"
      end
    end

    desc 'clean NAME', 'Clean an individual stack, by name'
    def clean(name)
      stack = Stack.new(name)
      print_warning "Cleaning: #{stack.name}"
      stack.clean
      print_ok "Cleaned: #{stack.name}"
    end

    #################################################################
    # HIDDEN TARGETED STACK TASKS
    # * These tasks are destructive in nature and do not require
    # regular use.
    #################################################################

    desc 'apply NAME', 'Apply an individual stack, by name', hide: true
    def apply(name)
      stack = Stack.new(name)
      print_warning "Applying: #{stack.name}"
      if stack.apply.zero?
        print_ok "Applied: #{stack.name}"
      else
        Stacks.error!(stack)
        print_crit "Failed to apply changes: #{stack.name}"
      end
    end

    desc 'refresh NAME', 'Refresh state on an individual stack, by name', hide: true
    def refresh(name)
      stack = Stack.new(name)
      print_crit "Refreshing: #{stack.name}"
      if stack.refresh.zero?
        print_warning "Refreshed: #{stack.name}"
      else
        Stacks.error!(stack)
        print_crit "Failed to refresh stack: #{stack.name}"
      end
    end

    desc 'destroy NAME', 'Destroy an individual stack, by name', hide: true
    def destroy(name)
      stack = Stack.new(name)
      print_crit "Destroying: #{stack.name}"
      if stack.destroy.zero?
        print_warning "Destroyed: #{stack.name}"
      else
        Stacks.error!(stack)
        print_crit "Failed to apply changes: #{stack.name}"
      end
    end

  end

end

