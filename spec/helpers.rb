module Helpers
  class << self
    def terraform_test_matrix
      {
        rev011: {
          version: '~> 0.11.15',
          upgradeable: true,
          artifacts: {
            plan:          'rev011.tfout',
            init:          '.terraform',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate.backup',
            destroy:       'terraform.tfstate.backup',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev012: {
          version: '~> 0.12.31',
          upgradeable: true,
          artifacts: {
            plan:          'rev012.tfout',
            init:          '.terraform',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate.backup',
            destroy:       'terraform.tfstate.backup',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev013: {
          version: '~> 0.13.7',
          upgradeable: true,
          artifacts: {
            plan:          'rev013.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev014: {
          version: '~> 0.14.11',
          upgradeable: true,
          artifacts: {
            plan:          'rev014.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev015: {
          version: '~> 0.15.3',
          upgradeable: false,
          artifacts: {
            plan:          'rev015.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_00: {
          version: '~> 1.0.0',
          upgradeable: true,
          artifacts: {
            plan:          'rev1_00.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_01: {
          version: '~> 1.1.0',
          upgradeable: true,
          artifacts: {
            plan:          'rev1_01.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_02_multi: {
          version: '~> 1.2.0',
          upgradeable: true,
          base_override: 'nested',
          artifacts: {
            plan:          'rev1_02_multi.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_02: {
          version: '~> 1.2.0',
          upgradeable: true,
          artifacts: {
            plan:          'rev1_02.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_03: {
          version: '~> 1.3.0',
          upgradeable: true,
          artifacts: {
            plan:          'rev1_03.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_04: {
          version: '~> 1.4.0',
          upgradeable: true,
          artifacts: {
            plan:          'rev1_04.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_05: {
          version: '~> 1.5.0',
          upgradeable: true,
          artifacts: {
            plan:          'rev1_05.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_06: {
          version: '~> 1.6.0',
          upgradeable: true,
          artifacts: {
            plan:          'rev1_06.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_07: {
          version: '~> 1.7.0',
          upgradeable: true,
          artifacts: {
            plan:          'rev1_07.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_08: {
          version: '~> 1.8.0',
          upgradeable: false,
          artifacts: {
            plan:          'rev1_08.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
        rev1_latest: {
          version: '~> 1.0',
          upgradeable: false,
          artifacts: {
            plan:          'rev1_latest.tfout',
            plan_file_obj: '.terraform/terradactyl.planfile.data',
            init:          '.terraform',
            apply:         'terraform.tfstate',
            refresh:       'terraform.tfstate',
            destroy:       'terraform.tfstate',
            lint:          'unlinted.tf',
            validate:      'invalid.tf',
          }
        },
      }
    end
  end

  @@original_cwd    = File.dirname(__FILE__)
  @@original_stderr = $stderr
  @@original_stdout = $stdout

  def disable_output
    $stderr = File.open(File::NULL, 'w')
    $stdout = File.open(File::NULL, 'w')
  end

  def enable_output
    $stderr = @@original_stderr
    $stdout = @@original_stdout
  end

  def original_work_dir
    @@original_cwd
  end

  def fixtures_dir
    File.join(original_work_dir, 'fixtures')
  end

  def cp_fixtures(tmpdir)
    raise unless Dir.exist?(tmpdir)
    cleanup = Dir.glob("#{tmpdir}/*", File::FNM_DOTMATCH).reject do |f|
      File.basename(f) =~ /^\.{1,2}$/
    end
    FileUtils.rm_rf(cleanup)
    FileUtils.cp_r("#{fixtures_dir}/.", tmpdir,  remove_destination: true)
  end

  def exe(cmd, working_dir)
    pwd = Dir.pwd
    cmd = %{bundle exec #{cmd}}
    Dir.chdir(working_dir)
    result = capture3(ENV, cmd)
    Dir.chdir(pwd)
    result
  end

  def capture3(env, cmd)
    results = %w[stdout stderr status].zip(Open3.capture3(env, *cmd))
    OpenStruct.new(Hash[results]).tap do |dat|
      dat.exitstatus = dat.status.exitstatus
    end
  end

  def silence(&block)
    disable_output
    yield
  ensure
    enable_output
  end

  def terraform_minimum
    '0.11.10'
  end

  def terraform_legacy
    terraform_resolve('~> 0.11.0')
  end

  def terraform_latest
    Terradactyl::Terraform::VersionManager.latest
  end

  def terraform_resolve(expression)
    Terradactyl::Terraform::VersionManager.resolve(expression)
  end

  def calculate_upgrade(current_version)
    maj, min, _rev = current_version.split('.')
    min = min.to_i < 13 ? (min.to_i + 1) : min
    VersionManager.resolve("~> #{maj}.#{min}.0")
  end
end
