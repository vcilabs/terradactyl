require 'spec_helper'

RSpec.describe Terradactyl::Terraform::Commands do
  before(:all) do
    @version    = '0.11.14'
    @options    = Terradactyl::Terraform::Commands::Options
    @stack_name = 'stack_a'
    @stack_dir  = "stacks/#{@stack_name}"
    @artifacts  = terraform_cmd_artifacts(@stack_dir)
    @artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }

    ENV['TF_PLUGIN_CACHE_DIR'] = File.expand_path('~/.terraform.d/plugins')
    Terradactyl::Terraform::VersionManager.install(@version)
  end

  after(:all) do
    @artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
    # Terradactyl::Terraform::VersionManager.remove(@version)
  end

  describe Terradactyl::Terraform::Commands::Fmt do
    let(:unlinted) do
      <<~LINT_ME
        resource "null_resource" "unlinted"
        {}
      LINT_ME
    end

    before(:each) do
      File.write(@artifacts.lint, unlinted)
      subject.dir_or_plan   = @stack_dir
      subject.options.quiet = true
    end

    after(:each) do
      FileUtils.rm_rf(@artifacts.lint) if File.exist?(@artifacts.lint)
    end

    describe 'formatting' do
      it 'formats the target stack' do
        expect(File.read(@artifacts.lint)).to eq(unlinted)
        expect(subject.execute).to eq(0)
        expect(File.read(@artifacts.lint)).not_to eq(unlinted)
      end
    end

    describe 'linting' do
      it 'just reports which files need formatting' do
        expect(File.read(@artifacts.lint)).to eq(unlinted)
        subject.options.list  = true
        subject.options.check = true
        expect(subject.execute).not_to eq(0)
        expect(File.read(@artifacts.lint)).to eq(unlinted)
      end
    end
  end

  describe Terradactyl::Terraform::Commands::Version do
    context 'with an empty or invalid dir_or_plan arg' do
      let(:command) { described_class.new }

      describe '#initialization' do
        it 'creates a new instance' do
          expect(command).to be_a described_class
        end
      end

      describe '#execute' do
        it 'outputs version information' do
          msg = 'Terraform v'
          expect {command.execute}.to output(/#{msg}\d+\.\d+\.\d+/).to_stdout
        end
      end

      describe '#execute with capture' do
        it 'captures version information' do
          msg = 'Terraform v'
          expect(command.execute(capture: true).stdout).to match(/#{msg}\d+\.\d+\.\d+/)
        end
      end
    end
  end

  describe Terradactyl::Terraform::Commands::Init do
    before(:each) do
      command.options.quiet = true
    end

    context 'with an empty or invalid dir_or_plan arg' do
      let(:command) { described_class.new }

      describe '#initialization' do
        it 'creates a new instance' do
          expect(command).to be_a described_class
        end
      end

      describe '#execute' do
        it 'should do nothing' do
          command.options.quiet = true
          silence { expect(command.execute).to eq(0) }
        end
      end
    end

    context 'with a valid dir_or_plan arg' do
      let(:command) { described_class.new(dir_or_plan: @stack_dir) }

      describe '#execute' do
        it 'inits the target stack' do
          expect(command.execute).to be_zero
          expect(Dir.exist?(@artifacts.init)).to be_truthy
        end
      end
    end

    context 'with a additional options' do
      let(:options) do
        @options.new({ no_color: true, echo: true })
      end

      let(:command) do
        described_class.new(dir_or_plan: @stack_dir, options: options)
      end

      describe '#execute' do
        it 'inits the target stack' do
          expect { command.execute }.to output(/Executing: .*-no-color.*/).to_stdout
          expect(Dir.exist?(@artifacts.init)).to be_truthy
        end
      end
    end
  end

  describe Terradactyl::Terraform::Commands::Plan do
    context 'with an empty or invalid args' do
      let(:command) { described_class.new }

      describe '#initialization' do
        it 'creates a new instance' do
          command.options.quiet = true
          expect(command).to be_a described_class
        end
      end

      describe '#execute' do
        it 'should fail' do
          command.options.quiet = true
          silence { expect(command.execute).to eq(1) }
        end
      end
    end

    context 'with a valid arguments' do
      let(:options) do
        @options.new({
          quiet: true,
          detailed_exitcode: true,
          state: @artifacts.apply,
          out: @artifacts.plan
        })
      end

      let(:command) do
        described_class.execute(dir_or_plan: @stack_dir, options: options)
      end

      describe '.execute' do
        it 'plans the target stack' do
          expect(command).to eq(2)
          expect(File.exist?(@artifacts.plan)).to be_truthy
        end
      end
    end
  end

  describe Terradactyl::Terraform::Commands::Show do
    context 'with an empty or invalid args' do
      let(:command) { described_class.new }

      describe '#initialization' do
        it 'creates a new instance' do
          command.options.quiet = true
          expect(command).to be_a described_class
        end
      end

      describe '#execute' do
        it 'should do nothing' do
          command.options.quiet = true
          silence { expect(command.execute).to eq(0) }
        end
      end
    end

    context 'with a valid arguments' do
      let(:options) do
        @options.new({
          quiet: false,
        })
      end

      let(:command) do
        described_class.execute(dir_or_plan: @artifacts.plan, options: options)
      end

      describe '.execute' do
        it 'plans the target stack' do
          expect {command}.to output(/null_resource.foo/).to_stdout
          silence { expect(command).to eq(0) }
        end
      end
    end
  end

  describe Terradactyl::Terraform::Commands::Apply do
    context 'with an empty or invalid args' do
      let(:command) { described_class.new }

      describe '#initialization' do
        it 'creates a new instance' do
          command.options.quiet = true
          expect(command).to be_a described_class
        end
      end

      describe '#execute' do
        it 'should fail' do
          command.options.quiet = true
          silence { expect(command.execute).to eq(1) }
        end
      end
    end

    context 'with a valid arguments' do
      let(:plan_file) { File.basename(@artifacts.plan) }

      let(:options) do
        @options.new({
          quiet: true,
          state_out: File.basename(@artifacts.apply),
        })
      end

      let(:command) do
        described_class.execute(dir_or_plan: plan_file, options: options)
      end

      before { Dir.chdir(@stack_dir) }
      after  { Dir.chdir('../../') }

      describe '.execute' do
        it 'applies the target stack' do
          expect(command).to eq(0)
          expect(File.exist?(File.basename(@artifacts.init))).to be_truthy
          expect(File.exist?(File.basename(@artifacts.plan))).to be_truthy
          expect(File.exist?(File.basename(@artifacts.apply))).to be_truthy
        end
      end
    end
  end

  describe Terradactyl::Terraform::Commands::Refresh do
    context 'with an empty or invalid args' do
      let(:command) { described_class.new }

      describe '#initialization' do
        it 'creates a new instance' do
          command.options.quiet = true
          expect(command).to be_a described_class
        end
      end

      describe '#execute' do
        after { FileUtils.rm('terraform.tfstate') }

        it 'create an empty statefile' do
          command.options.quiet = true
          silence { expect(command.execute).to eq(0) }
          expect(File.exist?('terraform.tfstate')).to be_truthy
        end
      end
    end

    context 'with a valid arguments' do
      let(:options) do
        @options.new({
          quiet: true,
          state: @artifacts.apply,
        })
      end

      let(:command) do
        described_class.execute(dir_or_plan: @stack_dir, options: options)
      end

      describe '.execute' do
        it 'refreshes the target stack' do
          expect(command).to eq(0)
          expect(File.exist?(@artifacts.refresh)).to be_truthy
        end
      end
    end
  end

  describe Terradactyl::Terraform::Commands::Destroy do
    context 'with an empty or invalid args' do
      let(:command) { described_class.new }

      describe '#initialization' do
        it 'creates a new instance' do
          command.options.quiet = true
          expect(command).to be_a described_class
        end
      end

      describe '#execute' do
        let(:statefile) { 'terraform.tfstate' }

        after { FileUtils.rm(statefile) if File.exist?(statefile) }

        it 'should fail' do
          command.options.quiet = true
          silence { expect(command.execute).to eq(1) }
        end
      end
    end

    context 'with a valid arguments' do
      let(:options) do
        @options.new({
          quiet: true,
          auto_approve: true,
          force: true,
          state: @artifacts.apply
        })
      end

      let(:command) do
        described_class.execute(dir_or_plan: @stack_dir, options: options)
      end

      describe '.execute' do
        it 'destroys the target stack' do
          expect(command).to eq(0)
          expect(File.exist?(@artifacts.destroy)).to be_truthy
        end
      end
    end
  end
end

