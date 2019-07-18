# frozen_string_literal: true

module Terradactyl
  module Terraform
    module Commands
      class Destroy < Base
        def defaults
          {
            'backup'       => nil,
            'auto-approve' => false,
            'force'        => false,
            'lock'         => true,
            'lock-timeout' => '0s',
            'no-color'     => true,
            'parallelism'  => 10,
            'refresh'      => true,
            'state'        => 'terraform.tfstate',
            'state-out'    => nil,
            # 'target'      => [], # not implemented
            # 'var'         => [], # not implemented
            'var-file'     => nil
          }
        end

        def switches
          %w[
            auto-approve
            force
            no-color
          ]
        end
      end
    end
  end
end
