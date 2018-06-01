module Terradactyl

  module Tasks

    include Rake::DSL

    extend self

    def install_tasks

      desc "Hello World!"
      task :hello do
        puts "Hello World!"
      end

    end

    Tasks.install_tasks

  end

end
