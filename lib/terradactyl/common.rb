module Terradactyl

  module Common

    COLUMN_WIDTH = 80
    BORDER_CHAR  = '#'

    Config.instance.environment.to_h.each do |variable, value|
      ENV[variable.to_s] = value
    end

    def config
      Config.instance
    end

    def terraform_path
      config.terraform.path || %{terraform}
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
      config.misc.utf8 ? "•" : "*"
    end

    def stack_icon
      config.misc.utf8 ? "  🥞  " : "  |||  "
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

    def print_dot(msg, color=:light_blue)
      string = "     #{dot_icon} #{msg}"
      puts string.send(color.to_sym)
    end

    def print_content(content)
      content.split("\n").each do |line|
        print_line line
      end
    end

    def print_line(msg, color=:light_blue)
      string = "     #{msg}"
      puts string.send(color.to_sym)
    end

    def print_message(msg, color=:light_blue)
      string = "#{stack_icon}[#{tag}] #{msg}"
      puts string.send(color.to_sym)
    end

    def print_header(msg)
      indent = centre + msg.size/2 - 1
      header = [border, ("#%#{indent}s" % "#{tag} | #{msg}"), border].join("\n")
      puts header.blue
      puts
    end

  end

end