# frozen_string_literal: true

module Terradactyl
  module Terraform
    module Commands
      class Show < Base
        def defaults
          {
            'module-depth' => -1,
            'no-color'     => false
          }
        end

        def switches
          %w[
            no-color
          ]
        end
      end
    end
  end
end
