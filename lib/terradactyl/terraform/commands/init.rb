# frozen_string_literal: true

module Terradactyl
  module Terraform
    module Commands
      class Init < Base
        def defaults
          {
            'backend'        => true,
            'backend-config' => nil,
            'from-module'    => nil,
            'get'            => true,
            'get-plugins'    => true,
            'input'          => true,
            'lock'           => true,
            'lock-timeout'   => '0s',
            'plugin-dir'     => nil,
            'upgrade'        => false,
            'verify-plugins' => true,
            'no-color'       => false,
            'force-copy'     => false,
            'reconfigure'    => false
          }
        end

        def switches
          %w[
            no-color
            force-copy
            reconfigure
          ]
        end
      end
    end
  end
end
