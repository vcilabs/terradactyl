lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'terradactyl/version'

Gem::Specification.new do |spec|
  spec.name        = "terradactyl"
  spec.version     = Terradactyl::VERSION
  spec.authors     = ["Brian Warsing", "Wade Peacock"]
  spec.email       = ["brian.warsing@alida.com", "wade.peacock@alida.com"]
  spec.license     = 'MIT'
  spec.summary     = %{Manage a Terraform monorepo}
  spec.description = %{Provides facility to manage a large Terraform monorepo}
  spec.homepage    = %{https://github.com/vcilabs/terradactyl}

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['changelog_uri']     = %{#{spec.homepage}/blob/main/CHANGELOG.md}
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.required_ruby_version = '>= 2.5.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0.20'
  spec.add_dependency 'colorize', '~> 0.8'
  spec.add_dependency 'deepsort', '~> 0.4'
  spec.add_dependency 'deep_merge', '~> 1.2'
  spec.add_dependency 'bundler', '>= 1.16'
  spec.add_dependency 'rake', '>= 10.0'
  spec.add_dependency 'terradactyl-terraform', '>= 1.4.1'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.12'
  spec.add_development_dependency 'pry-remote', '~> 0.1.8'
  spec.add_development_dependency 'rubocop', '~> 0.71.0'
end
