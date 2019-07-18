# frozen_string_literal: true

module Terradactyl
  module Terraform
    module Commands
      class Fmt < Base
        def defaults
          {
            'list'  => true,
            'write' => true,
            'diff'  => false,
            'check' => false
          }
        end

        def switches
          []
        end
      end
    end
  end
end
