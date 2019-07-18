module Helpers

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

  def terraform_build_artifacts(stack)
    OpenStruct.new({
      init:    "#{stack.path}/.terraform",
      plan:    "#{stack.path}/#{stack.name}.tfout",
      apply:   "#{stack.path}/terraform.tfstate",
      refresh: "#{stack.path}/terraform.tfstate.backup",
      destroy: "#{stack.path}/terraform.tfstate.backup",
      lint:    "#{stack.path}/unlinted.tf",
    })
  end

  def terraform_cmd_artifacts(stack_path)
    stack_name = stack_path.split('/').last
    OpenStruct.new({
      init:    "#{stack_path}/.terraform",
      plan:    "#{stack_path}/#{stack_name}.tfout",
      apply:   "#{stack_path}/terraform.tfstate",
      refresh: "#{stack_path}/terraform.tfstate.backup",
      destroy: "#{stack_path}/terraform.tfstate.backup",
      lint:    "#{stack_path}/unlinted.tf",
    })
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
    calculate_latest
  end

  def calculate_latest
    fh = Downloader.fetch(downloads_url)
    re = %r{#{releases_url}\/(?<version>\d+\.\d+\.\d+)}
    fh.read.match(re)['version']
  ensure
    fh.close
    fh.unlink
  end

  def downloads_url
    'https://www.terraform.io/downloads.html'
  end

  def releases_url
    'https://releases.hashicorp.com/terraform'
  end
end
