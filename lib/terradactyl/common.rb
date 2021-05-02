# frozen_string_literal: true

module Terradactyl
  module Common
    COLUMN_WIDTH = 80
    BORDER_CHAR  = '#'

    module_function

    def required_versions_re
      /(?<assignment>(?:\n\s)*required_version\s+=\s+)(?<value>".*?")/m
    end

    def supported_revisions
      Terradactyl::Commands.constants.select { |c| c =~ /Rev/ }.sort
    end

    def config
      @config ||= ConfigProject.instance
    end

    def terraform_binary
      config.terraform.binary || %(terraform)
    end

    def tag
      'Terradactyl'
    end

    def border
      BORDER_CHAR * COLUMN_WIDTH
    end

    def centre
      COLUMN_WIDTH / 2
    end

    def dot_icon
      config.misc.utf8 ? '•' : '*'
    end

    def stack_icon
      config.misc.utf8 ? '  𝓣  ' : '  |||  '
    end

    def print_crit(msg)
      print_message(msg, :light_red)
    end

    def print_ok(msg)
      print_message(msg, :light_green)
    end

    def print_warning(msg)
      print_message(msg, :light_yellow)
    end

    def print_content(content)
      content.split("\n").each do |line|
        print_line line
      end
      puts
    end

    def print_dot(msg, color = :light_blue)
      string = "     #{dot_icon} #{msg}"
      cputs(string, color)
    end

    def print_line(msg, color = :light_blue)
      string = "     #{msg}"
      cputs(string, color)
    end

    def print_message(msg, color = :light_blue)
      string = "#{stack_icon}[#{tag}] #{msg}"
      cputs(string, color)
      puts
    end

    def print_header(msg, color = :blue)
      indent  = centre + msg.size / 2 - 1
      content = format("#%#{indent}s", "#{tag} | #{msg}")
      string  = [border, content, border].join("\n")
      cputs(string, color)
      puts
    end

    def cputs(msg, color)
      puts config.misc.disable_color ? msg : msg.send(color.to_s)
    end
  end
end
