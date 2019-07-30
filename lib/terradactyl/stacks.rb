# frozen_string_literal: true

module Terradactyl

  class Stacks

    class << self

      @@dirty = []
      @@error = []

      def error
        @@error
      end

      def error!(stack)
        @@error << stack
      end

      def error?(name = nil)
        if name
          return @@error.find { |s| s.name.eql?(validate(name)) }
        end
        @@error.any?
      end

      def dirty
        @@dirty
      end

      def dirty!(stack)
        @@dirty << stack
      end

      def dirty?(name = nil)
        if name
          return @@dirty.find { |s| s.name.eql?(validate(name)) }
        end
        @@dirty.any?
      end

    end

    include Enumerable
    include Common

    def self.validate(stack)
      new.validate(stack)
    end

    def self.load(*args)
      new(*args)
    end

    def initialize(filter: StacksPlanFilterDefault.new)
      @base_dir = "#{Rake.original_dir}/#{config.base_folder}"
      @stacks   = filter.sift(stacks_all)
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
