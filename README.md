# Terradactyl

[![Gem Version](https://badge.fury.io/rb/terradactyl.svg)](https://badge.fury.io/rb/terradactyl)
![Build Status](https://github.com/vcilabs/terradactyl/workflows/Build%20Status/badge.svg)

Gem that provides a useful CLI interface for managing a Terraform monorepo.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'terradactyl'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install terradactyl

## Configuration

Configuration of Terradactyl is performed by placing a `terradactly.yaml` file in your Terraform repo.

Example:

    ---
    terradactyl:
      base_folder: my_project
      terraform:
        version: 0.11.10
        install_dir: ~/bin
        autoinstall: true
        apply:
          quiet: false
        destroy:
          quiet: false
      environment:
        AWS_REGION: us-west-2
        TF_PLUGIN_CACHE_DIR: ~/.terraform.d/plugins
      misc:
        disable_color: false
        utf8: true
      cleanup:
        empty: true
        match:
          - "*.tfstate*"
          - "*.tfout"
          - "*.tflock"
          - "*.zip"
          - ".terraform"

## Usage

For a list of available tasks do:

    terradactyl help

## Contributing

Bug reports and pull requests are welcome on GitHub at https://git.vcilabs.com/CloudEng/terradactyl.
