require 'pry'
require 'rake'
require 'open3'
require 'yaml'
require 'ostruct'
require 'singleton'

require_relative 'terradactyl/version'
require_relative 'terradactyl/config'
require_relative 'terradactyl/common'
require_relative 'terradactyl/terraform'
require_relative 'terradactyl/stack'
require_relative 'terradactyl/stacks'
require_relative 'terradactyl/filters'

include Terradactyl
include Common

TerraformVersion.seatbelt

# x = Stack.new "foo"
# x.init
# x.plan
# x.apply

# puts Stacks.new.list
# puts Stacks.new(filter: StacksFilterGitDiffHead.new).list

# Stacks.new.each do |stack|
#   puts "Stack: #{stack.name}"
#   stack.init
#   stack.plan
# end

# Stacks.new(filter: StacksPlanFilterGitDiffHead.new).each do |stack|
#   puts "Stack: #{stack.name}"
#   stack.init
#   stack.plan
# end

Stacks.load(filter: StacksApplyFilterPrePlanned.new).each do |stack|
  stack.apply
end
