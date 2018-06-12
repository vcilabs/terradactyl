module Terradactyl

  class Stacks

    class << self

      @@dirty = false

      def dirty
        @@dirty = true
      end

      def dirty?
        @@dirty
      end

    end

    include Enumerable

    def self.load(*args)
      new *args
    end

    def initialize(filter: StacksPlanFilterDefault.new)
      @base_dir = "#{Rake.original_dir}/#{config.base_folder}"
      @stacks   = filter.sift(stacks_all)
    end

    def list
      @stacks
    end

    def size
      @stacks.size
    end

    def each(&block)
      list.each(&block)
    end

    private

    def paths
      Dir.glob("#{@base_dir}/*/*.tf")
    end

    def stacks_all
      paths.map { |p| File.dirname(p) }.sort.uniq.map { |p| File.basename(p) }
    end

  end

end
