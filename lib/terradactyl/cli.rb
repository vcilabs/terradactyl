module Terradactyl

  class CLI < Thor

    no_commands {

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
          exit 0
        end
        stacks
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
      Stacks.load(filter: StacksApplyFilterPrePlanned.new).each do |stack|
        apply(stack)
      end
    end

    desc 'smartrefresh','Refresh any stacks that contain plan files', hide: true
    def smartrefresh
      print_header "SmartRefreshing Stacks ..."
      Stacks.load(filter: StacksApplyFilterPrePlanned.new).each do |stack|
        refresh(stack)
      end
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
      print_header "Cleaning All Stacks ..."
      Stacks.load.each { |stack| clean(stack) }
    end

    desc 'planall', 'Plan all stacks'
    def planall
      print_header "Planning ALL Stacks ..."
      Stacks.load.each do |stack|
        clean(stack)
        init(stack)
        plan(stack)
      end
    end

    desc 'auditall', 'Audit all stacks'
    def auditall
      print_header "Auditing ALL Stacks ..."
      Stacks.load.each do |stack|
        clean(stack)
        init(stack)
        audit(stack)
      end
      abort if Stacks.dirty?
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
        print_warning "Bad Formatting: #{stack.name}"
        abort
      end
    end

    desc 'fmt NAME', 'Format an individual stack, by name'
    def fmt(name)
      stack = Stack.new(name)
      print_warning "Formatting: #{stack.name}"
      if stack.fmt.zero?
        print_ok "Formatted: #{stack.name}"
      else
        print_crit "Formatting failed: #{stack.name}"
      end
    end

    desc 'init NAME', 'Init an individual stack, by name'
    def init(name)
      stack = Stack.new(name)
      print_ok "Initializing: #{stack.name}"
      if stack.init.zero?
        print_ok "Initialized: #{stack.name}"; puts
      else
        print_crit "Initialization failed: #{stack.name}"; abort
      end
    end

    desc 'plan NAME', 'Plan an individual stack, by name'
    def plan(name)
      stack = Stack.new(name)
      print_ok "Planning: #{stack.name}"; puts
      case stack.plan
      when 0
        print_ok "No changes: #{stack.name}"; puts
      when 1
        print_crit "Plan failed: #{stack.name}"; abort
      when 2
        Stacks.dirty!
        print_warning "Changes detected: #{stack.name}"; puts
        stack.show_plan_file
      else
        fail
      end
    end

    desc 'audit NAME', 'Audit an individual stack, by name'
    def audit(name)
      plan(name)
      if Stacks.dirty?
        print_crit "Dirty stack: #{name}"; puts
        abort
      end
    end

    desc 'clean NAME', 'Clean an individual stack, by name'
    def clean(name)
      stack = Stack.new(name)
      print_warning "Cleaning: #{stack.name}"; puts
      stack.clean
      print_ok "Cleaned: #{stack.name}"; puts
    end

    #################################################################
    # HIDDEN TARGETED STACK TASKS
    # * These tasks are destructive in nature and do not require
    # regular use.
    #################################################################

    desc 'apply NAME', 'Apply an individual stack, by name', hide: true
    def apply(name)
      stack = Stack.new(name)
      print_warning "Applying: #{stack.name}"; puts
      if stack.apply.zero?
        print_ok "Applied: #{stack.name}"; puts
      else
        print_crit "Failed to apply changes: #{stack.name}"; abort
      end
    end

    desc 'refresh NAME', 'Refresh state on an individual stack, by name', hide: true
    def refresh(name)
      stack = Stack.new(name)
      print_crit "Refreshing: #{stack.name}"; puts
      if stack.refresh.zero?
        print_warning "Refreshed: #{stack.name}"; puts
      else
        print_crit "Failed to refresh stack: #{stack.name}"; abort
      end
    end

    desc 'destroy NAME', 'Destroy an individual stack, by name', hide: true
    def destroy(name)
      stack = Stack.new(name)
      print_crit "Destroying: #{stack.name}"; puts
      if stack.destroy.zero?
        print_warning "Destroyed: #{stack.name}"; puts
      else
        print_crit "Failed to apply changes: #{stack.name}"; abort
      end
    end

  end

end

