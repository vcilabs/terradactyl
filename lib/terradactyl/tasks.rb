module Terradactyl

  module Tasks

    include Rake::DSL

    extend self

    def parent_tasks
      Rake.application.top_level_tasks
    end

    def validate_name(args)
      raise 'ERROR: No stack name specified' unless name = args[:name]
      name
    end

    def validate_smartplan(stacks)
      if stacks.size == 0
        print_message "No Stacks Modified ..."
        print_line "Did you forget to `git add` your selected changes?"
        abort
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

    def install_tasks

      namespace :terradactyl do |namespace|

        task default: %w{ list }

        desc "Print version"
        task :version do
          print_message "version: %s" % Terradactyl::VERSION
        end

        desc 'List the stacks'
        task :list do
          print_ok "Stacks:"
          Stacks.load.each do |stack|
            print_dot "#{stack}"
          end
        end

        # desc 'Plan any stacks against Git FETCH_HEAD (used for PRs)'
        task :planpr do
          print_header "SmartPlanning PR ..."
          scope = namespace.scope.path
          stacks = Stacks.load(filter: StacksPlanFilterGitDiffFetchHead.new)
          validate_planpr(stacks).each do |stack|
            %i{clean init plan}.each do |op|
              Rake::Task["#{scope}:#{op}"].execute(name: stack)
            end
          end
        end

        desc 'Plan any stacks that differ from Git HEAD'
        task :smartplan do
          print_header "SmartPlanning Stacks ..."
          scope = namespace.scope.path
          stacks = Stacks.load(filter: StacksPlanFilterGitDiffHead.new)
          validate_smartplan(stacks).each do |stack|
            %i{clean init plan}.each do |op|
              Rake::Task["#{scope}:#{op}"].execute(name: stack)
            end
          end
        end

        # desc 'Apply any stacks that contain plan files (used for PRs)'
        task :smartapply do
          print_header "SmartApplying Stacks ..."
          scope = namespace.scope.path
          Stacks.load(filter: StacksApplyFilterPrePlanned.new).each do |stack|
            Rake::Task["#{scope}:apply"].execute(name: stack)
          end
        end

        # desc 'Refresh any stacks that contain plan files (used for PRs)'
        task :smartrefresh do
          print_header "SmartRefreshing Stacks ..."
          scope = namespace.scope.path
          Stacks.load(filter: StacksApplyFilterPrePlanned.new).each do |stack|
            Rake::Task["#{scope}:refresh"].execute(name: stack)
          end
        end

        desc 'Clean all stacks'
        task :cleanall do
          print_header "Cleaning All Stacks ..."
          scope = namespace.scope.path
          Stacks.load.each do |stack|
            Rake::Task["#{scope}:clean"].execute(name: stack)
          end
        end

        desc 'Plan all stacks'
        task :planall do
          print_header "Planning ALL Stacks ..."
          scope = namespace.scope.path
          Stacks.load.each do |stack|
            %i{clean init plan}.each do |op|
              Rake::Task["#{scope}:#{op}"].execute(name: stack)
            end
          end
        end

        desc 'Audit all stacks'
        task :auditall do
          print_header "Auditing ALL Stacks ..."
          scope = namespace.scope.path
          Stacks.load.each do |stack|
            %i{clean init plan}.each do |op|
              Rake::Task["#{scope}:#{op}"].execute(name: stack)
            end
          end
          abort if Stacks.dirty?
        end

        desc 'Lint an individual stack, by name'
        task :lint, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_ok "Linting: #{stack.name}"
          if stack.lint.zero?
            print_ok "Formatting OK: #{stack.name}"
          else
            print_warning "Bad Formatting: #{stack.name}"
            abort
          end
        end

        desc 'Format an individual stack, by name'
        task :fmt, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_warning "Formatting: #{stack.name}"
          if stack.fmt.zero?
            print_ok "Formatted: #{stack.name}"
          else
            print_crit "Formatting failed: #{stack.name}"
          end
        end

        desc 'Init an individual stack, by name'
        task :init, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_ok "Initializing: #{stack.name}"
          if stack.init.zero?
            print_ok "Initialized: #{stack.name}"; puts
          else
            print_crit "Initialization failed: #{stack.name}"; abort
          end
        end

        desc 'Plan an individual stack, by name'
        task :plan, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_ok "Planning: #{stack.name}"; puts
          case stack.plan
          when 0
            print_ok "No changes: #{stack.name}"; puts
          when 1
            print_crit "Plan failed: #{stack.name}"; abort
          when 2
            Stacks.dirty
            print_warning "Changes detected: #{stack.name}"; puts
            stack.show_plan_file
          else
            fail
          end
        end

        desc 'Audit an individual stack, by name'
        task :audit, [:name] do |t,args|
          scope = namespace.scope.path
          stack = args[:name]
          Rake::Task["#{scope}:plan"].execute(name: stack)
          if Stacks.dirty?
            print_crit "Dirty stack: #{stack}"; puts
            abort
          end
        end

        # desc 'Apply an individual stack, by name'
        task :apply, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_warning "Applying: #{stack.name}"; puts
          if stack.apply.zero?
            print_ok "Applied: #{stack.name}"; puts
          else
            print_crit "Failed to apply changes: #{stack.name}"; abort
          end
        end

        # desc 'Refresh state on an individual stack, by name'
        task :refresh, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_crit "Refreshing: #{stack.name}"; puts
          if stack.refresh.zero?
            print_warning "Refreshed: #{stack.name}"; puts
          else
            print_crit "Failed to refresh stack: #{stack.name}"; abort
          end
        end

        # desc 'Apply an individual stack, by name'
        task :destroy, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_crit "Destroying: #{stack.name}"; puts
          if stack.destroy.zero?
            print_warning "Destroyed: #{stack.name}"; puts
          else
            print_crit "Failed to apply changes: #{stack.name}"; abort
          end
        end

        desc 'Clean an individual stack, by name'
        task :clean, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_warning "Cleaning: #{stack.name}"; puts
          stack.clean
          print_ok "Cleaned: #{stack.name}"; puts
        end

      end

    end

    Tasks.install_tasks

  end

end
