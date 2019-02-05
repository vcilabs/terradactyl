module Terradactyl

  class Stacks

    class << self

      @@dirty = []
      @@error = []

      def error!(stack)
        @@error << stack
      end

      def error?(stack=nil)
        return @@error.member?(stack) if stack
        @@error.any?
      end

      def dirty!(stack)
        @@dirty << stack
      end

      def dirty?(stack=nil)
        return @@dirty.member?(stack) if stack
        @@dirty.any?
      end

    end

    include Enumerable

    def self.validate(stack)
      new.validate(stack)
    end

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

    def validate(stack_name)
      @stacks.member? stack_name
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
