# Terradactyl

Gem that provides a useful CLI interface for managing a Terraform mono-repo.

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

Configuration of Terradactyl is performed by placing a `terraform.yml` file in your Terraform repo.

Example:

    ---
    terradactyl:
      base_folder: _test
      terraform:
        path: /path/to/terraform
        version: 0.11.1
        parallelism: 5
        lock: true
      environment:
        AWS_REGION: us-west-2
        TF_PLUGIN_CACHE_DIR: ~/.terraform_plugins
        TF_CLI_ARGS: -no-color
      misc:
        debug: false
        quiet: true
        disable_color: false

## Usage

For a list of available tasks do:

    terradactyl help

## Contributing

Bug reports and pull requests are welcome on GitHub at https://git.vcilabs.com/CloudEng/terradactyl.
