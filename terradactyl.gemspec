
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "terradactyl/version"

Gem::Specification.new do |spec|
  spec.name          = "terradactyl"
  spec.version       = Terradactyl::VERSION
  spec.authors       = ["Brian Warsing"]
  spec.email         = ["brian.warsing@visioncritical.com"]

  spec.summary       = %{Manage a Terraform mono-repo}
  spec.description   = %{Provides facility to manage a large Terraform mono-repo}
  spec.homepage      = %{https://git.vcilabs.com/CloudEng/terradactyl}

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://gems.media.service.consul:8808"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'thor', '~> 0.20'
  spec.add_dependency 'colorize', '~> 0.8'
  spec.add_dependency 'deepsort', '~> 0.4'
  spec.add_dependency "bundler", ">= 1.16"
  spec.add_dependency "rake", ">= 10.0"

  spec.add_development_dependency "rspec", "~> 3.0"
end
