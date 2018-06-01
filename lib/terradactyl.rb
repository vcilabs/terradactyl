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

include Terradactyl
include Common

TerraformVersion.seatbelt

# x = Stack.new "foo"
# x.init
# x.plan
# x.apply

puts Stacks.new.list