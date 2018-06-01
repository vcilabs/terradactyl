module Terradactyl

  class StacksFilterDefault

    def sift(stacks)
      stacks
    end

  end

  class StacksFilterGitDiff

    def sift(stacks)
      modified = %x{git --no-pager diff --name-only}.split
      stacks && modified.map { |p| File.dirname(p) }.sort.uniq!
    end

  end

  class Stacks

    attr_reader :stacks

    def initialize(filter: StacksFilterDefault.new)
      @filter   = filter
      @base_dir = "#{Rake.original_dir}/#{config.base_folder}"
      @paths    = Dir.glob("#{@base_dir}/**/*.tf")
    end

    def stacks_all
      @paths.map { |p| File.dirname(p) }.sort.uniq
    end

    def list
      @stacks ||= @filter.sift(stacks_all).map { |p| File.basename(p) }
    end

  end

end
