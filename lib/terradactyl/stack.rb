module Terradactyl

  class Stack

    def initialize(stack_name)
      @stack_name = stack_name
      @base_dir   = "#{Rake.original_dir}/#{config.base_folder}"
      @stack_path = "#{@base_dir}/#{@stack_name}"
      @plan_path  = "#{@base_dir}/#{@stack_name}/#{@stack_name}.tfout"
      expand_path_vars
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
      abort "FATAL: no plan exists for stack: #{stack_name}" unless has_plan?
      execute terraform_path, :apply, '-refresh=true', "-lock=#{lock}",
        "-parallelism=#{parallelism}", plan_path
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

    private

    attr_reader :stack_name, :base_dir, :stack_path, :plan_path

    def expand_path_vars
      ENV['TF_PLUGIN_CACHE_DIR'] = File.expand_path(ENV['TF_PLUGIN_CACHE_DIR'])
    end

    def execute(*args)
      args.map!(&:to_s)
      Open3.popen2e(ENV, *args) do |stdin, stdout_err, wait_thru|
        puts $_ while stdout_err.gets
        wait_thru.value.exitstatus
      end
    end
  end

end
