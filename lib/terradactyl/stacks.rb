module Terradactyl

  class StacksFilterDefault

    def sift(stacks)
      stacks
    end

  end

  class StacksFilterGitDiffHead

    def git_cmd
      %x{git --no-pager diff --name-only HEAD}
    end

    def sift(stacks)
      Dir.chdir config.base_folder
      stacks & git_cmd.split.map { |p| File.dirname(p) }.sort.uniq
    end

  end

  class StacksFilterGitDiffFetchHead < StacksFilterGitDiffHead

    def git_cmd
      %x{git --no-pager diff --name-only FETCH_HEAD ORIG_HEAD}
    end

  end

  class Stacks

    include Enumerable

    def initialize(filter: StacksFilterDefault.new)
      @base_dir = "#{Rake.original_dir}/#{config.base_folder}"
      @stacks   = filter.sift(stacks_all).map { |s| Stack.new(s) }
    end

    def list
      @stacks
    end

    def each(&block)
      list.each(&block)
    end

    private

    def paths
      Dir.glob("#{@base_dir}/**/*.tf")
    end

    def stacks_all
      paths.map { |p| File.dirname(p) }.sort.uniq.map { |p| File.basename(p) }
    end

  end

end
