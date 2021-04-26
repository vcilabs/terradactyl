module Helpers
  class << self
    def terraform_test_matrix
      {
        rev011: {
          version: '0.11.14',
          stack_name: 'rev011',
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
          version: '0.12.30',
          stack_name: 'rev012',
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
          version: '0.13.6',
          stack_name: 'rev013',
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
          version: '0.14.10',
          stack_name: 'rev014',
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
          version: '0.15.0',
          stack_name: 'rev015',
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
    '0.11.14'
  end

  def terraform_latest
    Terradactyl::Terraform::VersionManager.latest
  end
end
