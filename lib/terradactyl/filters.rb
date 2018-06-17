module Terradactyl

  class StacksPlanFilterDefault

    def base_dir
      config.base_folder
    end

    def stack_name(path)
      path.split('/')[1]
    end

    def sift(stacks)
      stacks
    end

  end

  class StacksPlanFilterGitDiffHead < StacksPlanFilterDefault

    def git_cmd
      %x{git --no-pager diff --name-only HEAD}
    end

    def sift(stacks)
      modified = git_cmd.split.inject([]) do |memo,path|
        memo << stack_name(path) if path =~ /#{base_dir}/
        memo
      end
      stacks & modified
    end

  end

  class StacksPlanFilterGitDiffFetchHead < StacksPlanFilterGitDiffHead

    def git_cmd
      %x{git --no-pager diff --name-only FETCH_HEAD ORIG_HEAD}
    rescue
      String.new
    end

  end

  class StacksPlanFilterGitDiffOriginBranch < StacksPlanFilterGitDiffHead

    def current_branch
      %x{git symbolic-ref -q --short HEAD}
    end

    def git_cmd
      %x{git --no-pager diff --name-only origin/#{current_branch}}
    rescue
      String.new
    end

  end

  class StacksApplyFilterDefault < StacksPlanFilterDefault
  end

  class StacksApplyFilterPrePlanned

    def sift(stacks)
      Dir.chdir config.base_folder
      stacks & Dir.glob('**/*.tfout').map { |p| File.dirname(p) }
    end

  end

end
