require 'bundler'
require 'open3'
require 'uri'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:doc) do |t|
  t.rspec_opts = "--format doc"
end

task :default => :spec

BUILD_DIR = 'pkg'

def bundler
  @bundler ||= Bundler::GemHelper.new
end

def execute(cmd)
  Open3.popen2e(ENV, cmd) do |stdin, stdout_err, wait_thru|
    puts $_ while stdout_err.gets
    wait_thru.value.exitstatus
  end
end

def name
  bundler.gemspec.name
end

def version
  bundler.gemspec.version
end

def allowed_push_host
  bundler.gemspec.metadata['allowed_push_host'] || String.new
end

def gem_server
  URI.parse(allowed_push_host).host
end

def resultant_gem
  "#{BUILD_DIR}/#{name}-#{version}.gem"
end

desc "Build gem"
task :build do
  bundler.build_gem
end

desc "Clean all builds"
task :clean do
  FileUtils.rm_rf BUILD_DIR if File.exist? BUILD_DIR
end
