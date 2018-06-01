module Terradactyl

  class StacksPlanFilterDefault

    def sift(stacks)
      stacks
    end

  end

  class StacksPlanFilterGitDiffHead

    def git_cmd
      %x{git --no-pager diff --name-only HEAD}
    end

    def sift(stacks)
      Dir.chdir config.base_folder
      stacks & git_cmd.split.map { |p| File.dirname(p) }.sort.uniq
    end

  end

  class StacksPlanFilterGitDiffFetchHead < StacksPlanFilterGitDiffHead

    def git_cmd
      %x{git --no-pager diff --name-only FETCH_HEAD ORIG_HEAD}
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
