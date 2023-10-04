# CHANGELOG

## 1.6.0 (2023-10-04)

NEW FEATURES:

* add support for Terraform version '~> 1.6.0`

## 1.5.0 (2023-06-12)

NEW FEATURES:

* add support for Terraform version '~> 1.5.0`

## 1.4.2 (2023-03-21)

BUG FIX:

* update depends on terradactyl-terraform to '>= 1.4.1'

## 1.4.1 (2023-03-14)

NEW FEATURES:

* add support for Terraform version '~> 1.4.0`
* add TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE as a default terradactyl configuration

## 1.4.0 (2022-09-21)

NEW FEATURES:

* add support for multiple stack subdirectories
* add optional BASE_FOLDER input for most Terradactyl commands

BUG FIXES:

* fix StacksApplyFilterPrePlanned filtering behaviour

## 1.3.0 (2022-09-21)

NEW FEATURES:

* add support for Terraform version '~> 1.3.0`

## 1.2.1 (2022-06-13)

BUG FIX:

* update depends on terradactyl-terraform to '>= 1.2.1'

## 1.2.0 (2022-05-18)

NEW FEATURES:

* add support for Terraform version '~> 1.2.0`

BUG FIX:

* fix CHANGELOG.md URL in gemspec

## 1.1.2 (2021-01-05)

BUG FIX:

* Align with changes to terradactyl-terraform (v1.1.2)

```
/var/lib/gems/2.7.0/gems/terradactyl-1.1.0/lib/terradactyl/stack.rb:73:in `block in setup_terraform': undefined method `downloads_url=' for Terradactyl::Terraform::VersionManager:Module (NoMethodError)
```

## 1.1.0 (2021-12-09)

NEW FEATURES:

* add support for Terraform version '~> 1.1.0`

DEPENDENCIES:

* update depends on terradactyl-terraform to '>= 1.1.0'

UPGRADEABLE:

* set '~> 1.0.0` as upgradeable

## 1.0.0 (2021-06-09)

NEW FEATURES:

* add support for Terraform version `~> 1.0.0`

BUG FIXES:

* fix bad test matrix

## 0.15.3 (2021-05-14)

BUG FIXES:

* fix `auto-approve` on `destroy` subcommand for Terraform version 0.15
* update all tests to use latest minor rev

## 0.15.2 (2021-05-02)

NEW FEATURES:

* make all stacks upgradeable, regardless of binary version
* add warning after upgrading to Terrafrom version 0.13
* expanded testing

BUG FIXES:

* do not init backend during upgrade
* fix edge case on stacks with no `versions.tf` file

## 0.15.1 (2021-04-28)

BUG FIXES:

* repair broken `upgrade` subcommand
  * fix malformed HCL substitution
  * fix regex match order of operations bug
  * make the feature more robust
  * add better feedback

## 0.15.0 (2021-04-27)

NEW FEATURES:

* add support for Terraform version `0.14.x`
* add support for Terraform version `0.15.x`
* add new subcommand `install`
  * generic component installation; presently only supports `terraform`
    - permits on-demand installation of any available Terraform binary
* add new subcommand `upgrade`
  * performs a Terraform upgrade of the target stack
* add support for native HCL Terraform contraints
  * terradactyl will now search for Terraform version contraints in the following files: `settings.tf`, `versions.tf` and `backend.tf`
* update version expression parsing to match Terraform's own
  * terradactyl version expression parsing should now operate the same way Terraform's own does, including support for version ranges

## 0.13.2 (2020-12-09)

BUG FIXES:

* replace symlink to executable with identical copy
  - `gem build` produces broken symlinks; unsupported

## 0.13.1 (2020-12-09)

BUG FIXES:

* update README to include missing acknowledgments

## 0.13.0 (2020-11-26)

NEW FEATURES:

* update Gem version string to match supported Terraform revision
* adds support for Terraform version 0.13.x
* adds implicit Terraform version management
  - (i.e. pessimistic operator, ~> 0.12.1)
* adds `defaults` sub-command

BUG FIXES:

* remove poor and non-critical defaults
* add CHANGELOG, LICENSE
* update README and provide examples
* fix/refactor/re-org tests and

## 0.11.0 (2019-09-12)

NEW FEATURES:

* overhaul Terradactyl::Commands
  - create dynamic Module mix-in for Stack
  - ensure command revision module prepends Commands
* overhaul Stack#plan and related code to use new Terraform::PlanFile class

## 0.10.0 (2019-09-06)

NEW FEATURES:

* update to work with `terradactyl-terraform`, `0.3.1`
* trap SIGINT to quell stack dumps on ^C
* hyphenate meta-subcommands, like `clean-all`
* add CLI subcommands `validate` and `validate-all`
* modularize Terraform subcommands by revision
  - add Terradactyl::Commands and revision sub-modules
  - add spec tests for both major revs
* refactor method decoration routine

## 0.9.2 (2019-09-06)

BUG FIXES:

* update Filter classes
  - ensure all git-related ops are performed on relative path
  - conform the default class by giving it a `git_cmd`
* update Stack
  - allow `decorate_cmds` to handle method args
  - make `validate_stack_name` err msg more generic
* make Stacks target filter accessible via ivar

## 0.9.1 (2019-09-05)

BUG FIXES:

* add Stack#validation and Stack#checklist
* update Stack filter classes with names and descriptions

## 0.9.0 (2019-09-03)

NEW FEATURES:

* update to work with supporting gem (`terradactyl-terraform`, `0.3.0`)
  - implement autoinstall (removed from supporting gem)
  - fix some spec tests
* refactor `Stack` command methods; DRY code
* cleanup some Rubocop violations

## 0.8.1 (2019-07-26)

BUG FIXES:

* rename method `has_plan?` to `planned?`
* add method: `plan_file_obj`; refactor plan file related methods
* refactor `common` and `config`
  - factor out early config loading for `String.disable_colorization`
  - fixes load failure when requiring the gem
* fix & refactor `Stack` and `Stacks` validation
  - fix bug when `td audit` is passed a stack path
  - move the path to stack name conversion into `Stacks.validate`

## 0.8.0 (2019-07-19)

NEW FEATURES:

* jettison code that migrated to `terradactyl-terraform` gem
* make `terradactyl-terraform` a dependency

## 0.6.1 (2019-03-12)

BUG FIXES:

* we can't parse "JSON-like" templates because they contain bare tokens
* rescue `JSON::ParserError` on misidentified blobs in `TerraformPlan#normalize_line`

## 0.6.0 (2019-03-04)

NEW FEATURES:

* re-organize terraform related code into component files
* add Gemfile.lock to .gitignore

## 0.5.9 (2019-02-05)

NEW FEATURES:

* add report feature to `auditall`

## 0.5.8 (2019-02-04)

BUG FIXES:

* re-classify stacks that error as errors, not dirty
* only abort on errors, not dirty stacks

## 0.5.7 (2019-01-31)

BUG FIXES:

* mark stacks as `dirty` on error or changed
* remove early exits (abort); throw `:error` as required
* add `at_exit` handler to catch dirty/error stacks
* new feature: support relative path to stack (tab-complete friendly), example: `td quickplan global/my-stack`
* add validation routine to stack names; better error message
* fix documentation

## 0.5.6 (2019-01-18)

BUG FIXES:

* change bundler pin posture to `>=`

## 0.5.5 (2018-07-09)

BUG FIXES:

* cosmetic: replace bold markdown with h4 header; better viz in Slack

## 0.5.4 (2018-07-05)

BUG FIXES:

* fix erroneous audit reporting

## 0.5.3 (2018-07-05)

BUG FIXES:

* fix CLI#auditall, rescue individual abort from CLI#audit
* update README

## 0.5.2 (2018-07-04)

BUG FIXES:

* fix Stack#execute, full IO buffer bug

## 0.5.1 (2018-06-30)

BUG FIXES:

* add base_folder attribute to TerraformPlan class
* fix JSON normalization routine in TerraformPlan class
  - was not handling lines that contained a mix of JSON blobs and regular Strings
  - refine the regex to add plain string handling

## 0.5.0 (2018-06-24)

NEW FEATURES:

* abandon Rake tasks as an interface
* replace with Thor CLI
* add `quickplan[NAME]` meta-task, per `terraenv`

## 0.4.1 (2018-06-18)

BUG FIXES:

* don't abort on empty Stacks for terradactyl:smartplan, just warn

## 0.4.0 (2018-06-18)

NEW FEATURES:

* permit cub-commands to be individually configured
* make state locking a per-operation config

## 0.3.9 (2018-06-18)

BUG FIXES:

* do not lock state during an init operation

## 0.3.8 (2018-06-18)

BUG FIXES:

* fix JSON unescape operation

## 0.3.7 (2018-06-16)

BUG FIXES:

* fix condition inversion

## 0.3.6 (2018-06-16)

BUG FIXES:

* fix Git diff filters stack_name extrapolation

## 0.3.5 (2018-06-16)

NEW FEATURES:

* add plan filter: StackPlanFilterDiffOriginBranch
* use new filter in PR planning operations

## 0.3.4 (2018-06-16)

BUG FIXES:

* fix missing dependency
* flag plan object as modified when there are changes

## 0.3.3 (2018-06-15)

BUG FIXES:

* do not lock state during a plan operation

## 0.3.2 (2018-06-14)

BUG FIXES:

* add JSON normalization routine to TerraformPlan class that will hopefully prevent checksum drift from plan to plan

## 0.3.1 (2018-06-12)

BUG FIXES:

* fix missing summary condition
