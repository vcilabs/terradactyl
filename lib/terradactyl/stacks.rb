module Terradactyl

  class Stacks

    include Enumerable

    def self.load(*args)
      new *args
    end

    def initialize(filter: StacksPlanFilterDefault.new)
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
