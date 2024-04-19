# frozen_string_literal: true

module Terradactyl
  class Stacks
    class << self
      # rubocop:disable Style/ClassVars
      @@dirty = []
      @@error = []

      def error
        @@error
      end

      def error!(stack)
        @@error << stack
      end

      def error?(name = nil)
        return @@error.find { |s| s.name.eql?(validate(name)) } if name

        @@error.any?
      end

      def dirty
        @@dirty
      end

      def dirty!(stack)
        @@dirty << stack
      end

      def dirty?(name = nil)
        return @@dirty.find { |s| s.name.eql?(validate(name)) } if name

        @@dirty.any?
      end
      # rubocop:enable Style/ClassVars
    end

    include Enumerable
    include Common

    def self.validate(stack)
      new.validate(stack)
    end

    def self.load(*args, **kwargs)
      new(*args, **kwargs)
    end

    attr_reader :filter

    def initialize(filter: StacksPlanFilterDefault.new, base_override: nil)
      base_folder = base_override || config.base_folder

      @filter   = filter
      @base_dir = "#{Rake.original_dir}/#{base_folder}"
      @stacks   = @filter.sift(stacks_all, base_folder)
    end

    def list
      @stacks
    end

    def validate(stack_name)
      stack_name = stack_name.split('/').last
      @stacks.member?(stack_name) ? stack_name : nil
    end

    def size
      @stacks.size
    end

    def empty?
      list.empty?
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
