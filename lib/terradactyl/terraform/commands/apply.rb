# frozen_string_literal: true

module Terradactyl
  module Terraform
    module Commands
      class Apply < Base
        def defaults
          {
            'backup'       => nil,
            'auto-approve' => false,
            'lock'         => true,
            'lock-timeout' => '0s',
            'input'        => true,
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
            no-color
          ]
        end
      end
    end
  end
end
