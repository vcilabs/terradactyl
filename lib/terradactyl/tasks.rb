module Terradactyl

  module Tasks

    include Rake::DSL

    extend self

    def install_tasks

      namespace :terra do |namespace|

        task default: %w{ list }

        desc "Print version"
        task :version do
          print_message "version: %s" % Terradactyl::VERSION
        end

        desc 'List the stacks'
        task :list do
          print_message "Stacks:"
          Stacks.load.each do |stack|
            print_line "• #{stack}"
          end
        end

        desc 'Plan any stacks that differ from Git HEAD'
        task :smartplan, [:pr] do |t,args|
          print_header "SmartPlanning Stacks ..."
          scope = namespace.scope.path
          Stacks.load(filter: StacksPlanFilterGitDiffHead.new).each do |stack|
            %i{init plan}.each do |op|
              Rake::Task["#{scope}:#{op}"].execute(name: stack)
            end
          end
        end

        desc 'Apply any stacks that contain plan files'
        task :smartapply do
          print_header "SmartPlanning Stacks ..."
          scope = namespace.scope.path
          Stacks.load(filter: StacksPlanFilterGitDiffHead.new).each do |stack|
            %i{init plan}.each do |op|
              Rake::Task["#{scope}:#{op}"].execute(name: stack)
            end
          end
        end

        desc 'Lint an individual stack, by name'
        task :lint, [:name] do |t,args|
          raise 'ERROR: No stack name specified' unless name = args[:name]
          stack = Stack.new(name)
          print_message "Linting Stack: #{stack.name}"
          if stack.lint.zero?
            print_ok "Formatting OK: #{stack.name}"
          else
            print_warning "Formatting required: #{stack.name}"
            abort
          end
        end

        desc 'Format an individual stack, by name'
        task :fmt, [:name] do |t,args|
          raise 'ERROR: No stack name specified' unless name = args[:name]
          stack = Stack.new(name)
          print_message "Formatting Stack: #{stack.name}"
          if stack.fmt.zero?
            print_ok "Formatted: #{stack.name}"
          else
            print_crit "Formatting failed: #{stack.name}"
          end
        end

        desc 'Init an individual stack, by name'
        task :init, [:name] do |t,args|
          raise 'ERROR: No stack name specified' unless name = args[:name]
          stack = Stack.new(name)
          print_message "Initializing Stack: #{stack.name}"
          if stack.init.zero?
            print_ok "Initialized: #{stack.name}"; puts
          else
            print_crit "Initialization failed: #{stack.name}"; abort
          end
        end

        desc 'Plan an individual stack, by name'
        task :plan, [:name] do |t,args|
          raise 'ERROR: No stack name specified' unless name = args[:name]
          stack = Stack.new(name)
          print_message "Planning Stack: #{stack.name}"
          case stack.plan
          when 0
            print_ok "No changes: #{stack.name}"; puts
          when 1
            print_crit "Plan failed: #{stack.name}"; abort
          when 2
            print_message 'Changes detected: #{stack.name}'; puts
          else
            fail
          end
        end

        desc 'Apply an individual stack, by name'
        task :apply, [:name] do |t,args|
          raise 'ERROR: No stack name specified' unless name = args[:name]
          stack = Stack.new(name)
          print_message "Applying Stack: #{stack.name}"
          if stack.apply.zero?
            print_ok 'Changes Applied: #{stack.name}'; puts
          else
            print_crit "Failed to apply changes: #{stack.name}"; abort
          end
        end

        # desc 'Clean an individual stack, by name'
        # task :clean, [:name] do |t,args|
        #   raise 'ERROR: No stack name specified' unless name = args[:name]
        #   stack = Stack.new(name)
        #   print_header "Cleaning Stack: #{stack.name}"
        #   stack.clean
        # end

      end

    end

    Tasks.install_tasks

  end

end
