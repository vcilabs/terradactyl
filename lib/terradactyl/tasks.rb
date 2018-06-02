module Terradactyl

  module Tasks

    include Rake::DSL

    extend self

    def install_tasks

      desc "Lint an individual stack, by name"
      task :lint, [:name] do |t,args|
        raise 'ERROR: No stack name specified' unless name = args[:name]
        stack = Stack.new(name)
        print_header "Linting Stack: #{stack.name}"
        if stack.lint.zero?
          print_ok 'Formatting OK!'
        else
          print_warning 'One or more files require formatting ...'
          abort
        end
      end

      desc "Format an individual stack, by name"
      task :fmt, [:name] do |t,args|
        raise 'ERROR: No stack name specified' unless name = args[:name]
        stack = Stack.new(name)
        print_header "Formatting Stack: #{stack.name}"
        if stack.fmt.zero?
          print_ok 'Formatting complete!'
        else
          print_crit 'Formatting failed!'
        end
      end

      desc "Init an individual stack, by name"
      task :init, [:name] do |t,args|
        raise 'ERROR: No stack name specified' unless name = args[:name]
        stack = Stack.new(name)
        print_header "Initializing Stack: #{stack.name}"
        if stack.init.zero?
          print_ok 'Initialized!'
        else
          print_crit 'Initialization failed!'; abort
        end
      end

      desc "Plan an individual stack, by name"
      task :plan, [:name] do |t,args|
        raise 'ERROR: No stack name specified' unless name = args[:name]
        stack = Stack.new(name)
        print_header "Planning Stack: #{stack.name}"
        case stack.plan
        when 0
          print_ok 'No changes ...'
        when 1
          print_crit 'Plan failed!'; abort
        when 2
          print_message 'Changes detected ...'
        else
          fail
        end
      end

      desc "Apply an individual stack, by name"
      task :apply, [:name] do |t,args|
        raise 'ERROR: No stack name specified' unless name = args[:name]
        stack = Stack.new(name)
        print_header "Applying Stack: #{stack.name}"
        if stack.apply.zero?
          print_ok 'Changes Applied ...'
        else
          print_crit 'Failed to apply changes!'; abort
        end
      end

    end

    Tasks.install_tasks

  end

end
