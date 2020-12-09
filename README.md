# Terradactyl

[![Gem Version](https://badge.fury.io/rb/terradactyl.svg)](https://badge.fury.io/rb/terradactyl)
![Build Status](https://github.com/vcilabs/terradactyl/workflows/Build%20Status/badge.svg)

CLI tooling for managing a Terraform monorepo.

## Overview

Terradactyl simplifies managing large heterogeneous Terraform monorepos by introducing hierarchical configuration and automatic management of Terraform versions on a per-stack basis.

## Features

* hierarchical configuration
* automatic Terraform binary installation
* "meta-commands" for consistent CI and development workflows

## Requirements

Requires Ruby 2.5 or greater.

NOTE: Terraform sub-command operations are only supported between stable versions `~> 0.11.x` and `~> 0.13.x`.

## Installation

### Bundler

Add this line to your application's Gemfile ...

```ruby
gem 'terradactyl'
```

And then execute:

    $ bundle install

### Manual

    $ gem install terradactyl

## Quick Setup

Terradactyl repos rely on two simple organizational conventions:

* a single project-level `terradactly.yaml`
* a single subdirectory for your stacks

```sh
.
├── stacks
│   └── demo
│       └── example.tf
└── terradactyl.yaml
```

That's it! In fact, if you use the default subdirectory name of `stacks`, all your configuration file need contain is:

```yaml
terradactyl:
```

All other configuration, including `autoinstall` (default: `true`) are optional.

When your config file and `base_folder` are setup, try executing:

`terradactyl stacks` OR `td stacks`

See [examples](examples) for different setups.

## Quick Tutorial

##### NOTE: this will require an active internet connection so that the various Terraform binaries for each individual stack may be fetched and installed in the background.

#### set your working directory

    $ cd examples/multi-tf-stacks

#### execute terradactyl

The Terradactyl CLI is installed with a symlink so it may be called by its full name or its shortened name, `td`:

    $ terradactyl help
    $ td help

#### quickplan a single stack

You can specify the relative path to the stack OR the just the stack name. These two commands are equivalent:

    $ terradactyl quickplan tfv11
    $ terradactyl quickplan stacks/tfv11

#### apply a single stack

    $ terradactyl apply stacks/tfv11

#### audit and report

    $ terradactyl audit-all --report

When complete, you should have a JSON report that you can pass to other processes.

    $ cat stacks.audit.json

#### quickplan ALL stacks

    $ terradactyl plan-all

#### apply ANY stacks that have a plan file

    $ terradactyl smartapply

#### clean all the stacks

    $ terradactyl clean-all

NOTE: `*.tfstate*` files are not cleaned up by default for obvious reasons, so clean them up manually:

`git clean -fD` OR `find . -name "*.tfstate*" --delete`

See the [Configuration](#configuration) section for more info on how to control which files get removed during a `clean <stack>` or `clean-all` operation.

## Operation

NOTE: `terradactyl` (symlinked as `td`) ONLY operates in the root of your monorepo. In order to execute any sub-commands, your working directory must contain your project-level configuration file, otherwise you will receive this:

    FATAL: Could not load project file: `terradactyl.yaml`, No such file or directory @ rb_sysopen - terradactyl.yaml

### General

Generally speaking, Terradactyl operates on the principle of **plan file** (`*.tfout`) generation. This can be reduced to the following tenets:

1. You _MUST_ perform a `plan` operation on a stack before an `apply`
2. You _CANNOT_ `apply` a stack that does not contain a plan file

In some cases, this might seem onerous, but it pays dividends in team workflow and CI/CD contexts.

### Supported sub-commands

Terradactyl was created to facilitate the using Terraform in a CI environment. As such, some of the more exotic ad hoc user-focused sub-commands have not received any effort in integration. The following is a list of the supported Terraform sub-commands:

* apply
* destroy
* fmt
* init
* plan
* refresh
* validate

### Meta-commands

Terradactyl provides a few useful meta-commands that can help you avoid repetitive multi-phase Terraform operations. Here are a few ...

#### quickplan

Clean, initialize and plan a single stack in one operation.

    terradactly quickplan <stack>

#### smartapply/smartrefresh

Apply or Refresh _ANY_ stack containing a plan file.

    terradactly smartapply <stack>
    terradactly smartrefresh <stack>

### Getting Help

For a list of available sub-commands do:

    $ terradactyl help

For help on any individual sub-command do:

    $ terradactyl help <sub-command>

## Configuration

As previously mentioned, configuration is hierarchical. This means you may specify:

* one project-level configuration for ALL stacks
* an overriding stack-level configuration for each independent stack

See [examples](examples) for different setups.

##### NOTE: all project-level configurations are valid at the stack level except `base_folder` which is ignored.

You can dump the compiled configuration for your project using the `defaults` sub-command:

    terradactyl defaults
    td defaults

### Descriptions

```yaml
terradactyl:              <Object, Terradactyl config>
  base_folder:            <String, the sub-directory for all your Terraform stacks, default=stacks>
  terraform:              <Object, configuration to Terraform sub-commands and binaries>
    binary:               <String, path to the Terraform binary you wish to use, default=nil>
    version:              <String, explicit or implict Terraform version, default=nil>
    autoinstall:          <Bool, perform automatic Terraform installations, default=true>
    install_dir:          <String, path to Terraform installations, default=$HOME/bin>
    echo:                 <Bool, print currently executing terraform command, default=false>
    quiet:                <Bool, suppress currently executing terraform stdout, default=true>
    init:                 <Object, CLI options to sub-command init>
      lock:               <Bool, lock the state file when locking is supported, default=false>
      force_copy:         <Bool, suppress prompts about copying state data, default=true>
    plan:                 <Object, CLI options to sub-command plan>
      lock:               <Bool, lock the state file when locking is supported, default=false>
      parallelism:        <Int, limit the number of concurrent operations, default=5>
      detailed_exitcode:  <Bool, lock the state file when locking is supported, default=true>
    apply:                <Object, CLI options to sub-command apply>
      parallelism:        <Int, limit the number of concurrent operations, default=5>
    refresh:              <Object, CLI options to sub-command refresh>
      input:              <Bool, ask for input for variables if not directly set, default=false>
    destroy:              <Object, CLI options to sub-command destroy>
      parallelism:        <Int, limit the number of concurrent operations, default=5>
      force:              <Bool, skip interactive approval before destroying, default=true>
  environment:            <Object, shell environment variables>
    TF_PLUGIN_CACHE_DIR:  <String, path to common Terraform plugin directory, default=$HOME/.terraform.d/plugins>
  misc:                   <Object, misc Terradactyl settings>
    utf8:                 <Bool, use utf8 in stdout, default=true>
    disable_color:        <Bool, disable color in stdout, default=false>
  cleanup:                <Object, Terradactyl cleanup settings>
    empty:                <Bool, remove empty directories, default=true>
    match:                <Array, list of shell globs to match, default=["*.tfout", "*.tflock", "*.zip", ".terraform"]>
```

### Terraform sub-command arguments

Note that the config above contains config for Terraform sub-commands. for example:

```yaml
terradactyl:
  terraform:
    plan:
      lock: false
      parallelism: 5
      detailed_exitcode: true
```

Each of the keys in the `plan` object correspond to an argument passed to the `terraform` binary. For example, the config above would equate to ...

    terraform -lock=false -parallelism=5 -detailed-exitcode

There are two conventions to keep in mind when configuring sub-commands:

1. any sub-command option which toggles behaviour (i.e. `-detailed-exitcode`) requires a specific Boolean value of `true` OR `false`
2. any sub-command option that is hyphenated (i.e. `-detailed-exitcode`) is set in the config using an **underscore** (i.e `detailed_exitcode`)

If you need to tweak or augment any of the default arguments passed to any of the supported Terraform sub-commands, you can do so by adding them to the config.

Example:

```yaml
terradactyl:
  terraform:
    refresh:
      lock: false
      backup: /tmp/tfbackup
```

In addition, you can override the `echo` and `quiet` settings for any of the Terraform sub-commands:

```yaml
terradactyl:
  terraform:
    echo: false
    quiet: true
    apply:
      echo: true
      quiet: false
    destroy:
      echo: true
      quiet: false
```

This can assist in debugging.

### Terraform version management

#### Explicit versions

By default, Terradactyl will always use the **latest** stable version of Terraform. If you do not specify a version, you will always get the latest stable version of Terraform available.

But, as part of Terradactyl's configuration, you can specify a **project** Terraform version, making it the default for _your_ monorepo:

```yaml
terradactyl:
  terraform:
    version: 0.12.29
```

Still, because Terradactyl's configuration is hierarchic, in addition the default version you specify at the project level, **each stack** may also specify a different version of Terraform.

See [examples/multi-tf-version](examples/multi-tf-version) for this setup.

#### Implicit versions

Also, there is no need to pin a project or a stack to an explicit version. Instead, you can use a pessimistic operator to ensure you always have the most up-to-date version of a minor Terraform revision.

Example:

```yaml
terradactyl:
  terraform:
    version: ~> 0.13.5
```

That way, when the next Terraform `0.13` is released, you can begin using it immediately, but you will never have to worry about upgrading to `0.14` unsuspectingly.

In fact, there are a number of ways to express implicit versions ...

    ~> 0.11.14
    ~> 0.11
    >= 0.12
    < 0.12

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vcilabs/terradactyl.

## License

This code is released under the MIT License. See [LICENSE.txt](LICENSE.txt).

## Acknowledgments

Special thanks to [Riley Shott](https://github.com/Ginja) upon whose original design and work I based this Gem.
