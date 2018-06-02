module Terradactyl

  class Stack

    def initialize(stack_name)
      @stack_name = stack_name
      @base_dir   = "#{Rake.original_dir}/#{config.base_folder}"
      @stack_path = "#{@base_dir}/#{@stack_name}"
      @plan_path  = "#{@base_dir}/#{@stack_name}/#{@stack_name}.tfout"
      expand_path_vars
      init_env_vars
    end

    def parallelism
      @parallelism ||= config.terraform.parallelism
    end

    def lock
      @lock ||= config.terraform.lock
    end

    def init
      Dir.chdir stack_path
      execute terraform_path, :init, '-backend=true', "-lock=#{lock}",
        '-get=true', '-get-plugins=true', '-input=false', '-force-copy'
    end

    def plan
      Dir.chdir stack_path
      execute terraform_path, :plan, '-refresh=true', "-lock=#{lock}",
        '-detailed-exitcode', "-parallelism=#{parallelism}", "-out=#{plan_path}"
    end

    def has_plan?
      Dir.chdir stack_path
      File.exist? plan_path
    end

    def apply
      Dir.chdir stack_path
      execute terraform_path, :apply, '-refresh=true', "-lock=#{lock}",
        "-parallelism=#{parallelism}", plan_path
    end

    def destroy
      Dir.chdir stack_path
      execute terraform_path, :destroy, '-refresh=true', "-lock=#{lock}",
        "-parallelism=#{parallelism}", '-force'
    end

    def lint
      Dir.chdir stack_path
      execute terraform_path, :fmt, '-list=true', "-check=true"
    end

    def fmt
      Dir.chdir stack_path
      execute terraform_path, :fmt
    end

    def name
      @stack_name
    end

    def path
      @stack_path
    end

    def <=>(other)
      self.name <=> other.name
    end

    def to_s
      "<name: #{name}, path: #{path}>"
    end

    def remove_plan_file
      print_line "• Removing Plan File: #{File.basename(@plan_path)}"
      FileUtils.rm_rf @plan_path
    end

    def show_plan_file
      if config.misc.quiet
        config.misc.quiet = false
        execute terraform_path, :show, plan_path
        config.misc.quiet = true
      end
    end

    def clean
      Dir.chdir stack_path
      removals = config.cleanup.match.map { |p| Dir.glob("**/#{p}") }
      removals << %x{find . -type d -empty}.split if config.cleanup.empty
      removals.flatten.sort.uniq.each do |path|
        print_line "• Removing: #{path}"
        FileUtils.rm_rf path
      end
      puts
    end

    private

    attr_reader :stack_name, :base_dir, :stack_path, :plan_path

    def expand_path_vars
      ENV['TF_PLUGIN_CACHE_DIR'] = File.expand_path(ENV['TF_PLUGIN_CACHE_DIR'])
    end

    def init_env_vars
      if config.misc.disable_color
        flag = '-no-color'
        unless (args = ENV['TF_CLI_ARGS'].to_s.split(',')).member?(flag)
          ENV['TF_CLI_ARGS'] = [args, flag].compact.flatten.join(",")
        end
      end
    end

    def debug?
      config.misc.debug
    end

    def debug(args)
      print_line(args) if debug?
    end

    def execute(*args)
      args.map!(&:to_s)
      debug(args)
      result = Open3.popen3(ENV, *args) do |stdin, stdout, stderr, wait_thru|
        puts $_ while stdout.gets unless config.misc.quiet
        puts $_ while stderr.gets
        wait_thru.value.exitstatus
      end
      puts
      result
    end

  end

end
