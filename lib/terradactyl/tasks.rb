module Terradactyl

  module Tasks

    include Rake::DSL

    extend self

    def validate_name(args)
      raise 'ERROR: No stack name specified' unless name = args[:name]
      name
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
            print_line "• #{stack}"
          end
        end

        desc 'Plan any stacks that differ from Git HEAD'
        task :smartplan, [:pr] do |t,args|
          print_header "SmartPlanning Stacks ..."
          scope = namespace.scope.path
          Stacks.load(filter: StacksPlanFilterGitDiffHead.new).each do |stack|
            %i{clean init plan}.each do |op|
              Rake::Task["#{scope}:#{op}"].execute(name: stack)
            end
          end
        end

        desc 'Apply any stacks that contain plan files'
        task :smartapply do
          print_header "SmartApplying Stacks ..."
          scope = namespace.scope.path
          Stacks.load(filter: StacksApplyFilterPrePlanned.new).each do |stack|
            Rake::Task["#{scope}:apply"].execute(name: stack)
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
          print_header "SmartPlanning Stacks ..."
          scope = namespace.scope.path
          Stacks.load.each do |stack|
            %i{clean init plan}.each do |op|
              Rake::Task["#{scope}:#{op}"].execute(name: stack)
            end
          end
        end

        desc 'Lint an individual stack, by name'
        task :lint, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_message "Linting: #{stack.name}"
          if stack.lint.zero?
            print_ok "Formatting OK: #{stack.name}"
          else
            print_warning "Formatting Required: #{stack.name}"
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
            print_ok "No changes: #{stack.name}"
            stack.remove_plan_file; puts
          when 1
            print_crit "Plan failed: #{stack.name}"; abort
          when 2
            print_warning "Changes detected: #{stack.name}"; puts
          else
            fail
          end
        end

        desc 'Apply an individual stack, by name'
        task :apply, [:name] do |t,args|
          stack = Stack.new(validate_name(args))
          print_warning "Applying: #{stack.name}"; puts
          if stack.apply.zero?
            print_ok "Applied: #{stack.name}"; puts
          else
            print_crit "Failed to apply changes: #{stack.name}"; abort
          end
        end

        desc 'Apply an individual stack, by name'
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
          print_warning "Cleaning: #{stack.name}"
          stack.clean
          print_ok "Cleaned: #{stack.name}"; puts
        end

      end

    end

    Tasks.install_tasks

  end

end
