# frozen_string_literal: true

module Terradactyl
  class StacksPlanFilterDefault
    include Common

    def self.name
      'default'
    end

    def self.desc
      'A list of all stacks in the basedir'
    end

    def git_cmd
      `git ls-files .`
    end

    # def base_dir
    #   config.base_folder
    # end

    def stack_name(path)
      path.split('/')[1]
    end

    def sift(stacks, _base_dir)
      stacks
    end
  end

  class StacksPlanFilterGitDiffHead < StacksPlanFilterDefault
    def self.name
      'diff-head'
    end

    def self.desc
      'A list of all stacks that differ from Git HEAD'
    end

    def git_cmd
      `git --no-pager diff --name-only HEAD .`
    end

    def sift(stacks, base_dir)
      modified = git_cmd.split.each_with_object([]) do |path, memo|
        memo << stack_name(path) if path =~ /#{base_dir}/
      end
      stacks & modified
    end
  end

  class StacksPlanFilterGitDiffFetchHead < StacksPlanFilterGitDiffHead
    def self.name
      'diff-fetch-head'
    end

    def self.desc
      'A list of all stacks that differ from Git FETCH_HEAD'
    end

    def git_cmd
      `git --no-pager diff --name-only FETCH_HEAD ORIG_HEAD .`
    rescue StandardError
      String.new
    end
  end

  class StacksPlanFilterGitDiffOriginBranch < StacksPlanFilterGitDiffHead
    def self.name
      'diff-origin'
    end

    def self.desc
      'A list of all stacks that differ from Git origin/HEAD'
    end

    def current_branch
      `git symbolic-ref -q --short HEAD`
    end

    def git_cmd
      `git --no-pager diff --name-only origin/#{current_branch} .`
    rescue StandardError
      String.new
    end
  end

  class StacksApplyFilterDefault < StacksPlanFilterDefault
  end

  class StacksApplyFilterPrePlanned < StacksApplyFilterDefault
    def sift(stacks, base_dir)
      targets = Dir.glob("#{base_dir}/**/*.tfout").each_with_object([]) do |path, memo|
        memo << path.split('/')[1]
      end
      stacks & targets
    end
  end
end
