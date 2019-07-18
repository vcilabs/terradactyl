# frozen_string_literal: true

module Terradactyl
  module Terraform
    module Commands
      class Refresh < Base
        def defaults
          {
            'backup'       => nil,
            'input'        => true,
            'lock'         => true,
            'lock-timeout' => '0s',
            'no-color'     => true,
            'state'        => 'terraform.tfstate',
            'state-out'    => nil,
            # 'target'      => [], # not implemented
            # 'var'         => [], # not implemented
            'var-file'     => nil
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
