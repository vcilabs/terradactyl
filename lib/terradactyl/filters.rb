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
      modified = git_cmd.split.inject([]) do |memo,path|
        parent_dir = File.dirname(path)
        stack_name = File.basename(parent_dir)
        memo << stack_name; memo
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

  class StacksApplyFilterDefault < StacksPlanFilterDefault
  end

  class StacksApplyFilterPrePlanned

    def sift(stacks)
      Dir.chdir config.base_folder
      stacks & Dir.glob('**/*.tfout').map { |p| File.dirname(p) }
    end

  end

end
