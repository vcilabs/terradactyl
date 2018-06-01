module Terradactyl

  module Common

    Config.instance.environment.to_h.each do |variable, value|
      ENV[variable.to_s] = value
    end

    def config
      Config.instance
    end

    def terraform_path
      Config.instance.terraform.path || %{terraform}
    end

  end

end