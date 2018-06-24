require 'thor'
require 'rake'
require 'open3'
require 'yaml'
require 'ostruct'
require 'singleton'
require 'colorize'
require 'deepsort'

require_relative 'terradactyl/version'
require_relative 'terradactyl/config'
require_relative 'terradactyl/common'
require_relative 'terradactyl/terraform'
require_relative 'terradactyl/stack'
require_relative 'terradactyl/stacks'
require_relative 'terradactyl/filters'
require_relative 'terradactyl/cli'

include Terradactyl
include Common

String.disable_colorization = config.misc.disable_color

TerraformVersion.seatbelt
