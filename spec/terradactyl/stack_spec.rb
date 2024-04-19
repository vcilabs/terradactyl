require 'spec_helper'

RSpec.describe Terradactyl::Stack do
  Helpers.terraform_test_matrix.each_pair do |rev, info|
    context "when Terraform version is #{rev}" do
      let(:stack_name)    { rev.to_s }
      let(:base_override) { info[:base_override] }
      let(:stack)         { silence { Terradactyl::Stack.new(stack_name, base_override) } }
      let(:stack_path)    { stack.path }
      let(:config)        { stack.config }
      let(:unlinted) do
        <<~LINT_ME
          resource "null_resource" "unlinted"{}
        LINT_ME
      end

      let(:tf_version) { stack.terraform.version }

      let(:tf_binary) { Terradactyl::Terraform::VersionManager.binary }

      let(:invalid) do
        <<~INVALID
          variable "foo" {
            default = false
            type    = "map"
          }
        INVALID
      end

      let(:artifacts) {
        OpenStruct.new(
          info[:artifacts].each_with_object({}) do |(op,file), memo|
            memo[op] = "#{stack_path}/#{file}"
          end
        )
      }

      let(:install_error) do
        Terradactyl::Terraform::VersionManager::VersionManagerError
      end

      let(:install_error_msg) do
        Terradactyl::Terraform::VersionManager::ERROR_MISSING
      end

      let(:inventory_error) do
        Terradactyl::Terraform::VersionManager::InventoryError
      end

      let(:inventory_error_msg) do
        Terradactyl::Terraform::VersionManager::Inventory::ERROR_VERSION_MISSING
      end

      let(:tmpdir) { Dir.mktmpdir('rspec_terradactyl') }

      let(:plan_file_signature) do
        supported_rev = rev.match(/rev\d+(?:_(?:\d+|latest))*/i).to_s || rev
        eval("Terradactyl::Terraform::#{supported_rev.capitalize}::PlanFileParser::PLAN_FILE_SIGNATURE")
      end

      before(:each) do
        cp_fixtures(tmpdir)
        Dir.chdir(tmpdir)
      end

      after(:each) do
        Dir.chdir(original_work_dir)
      end

      before(:all) do
        Terradactyl::Terraform::VersionManager.binaries.each do |path|
          FileUtils.rm path
        end
        Terradactyl::Terraform::VersionManager.reset!
      end

      after(:all) do
        Terradactyl::Terraform::VersionManager.binaries.each do |path|
          FileUtils.rm path
        end
        Terradactyl::Terraform::VersionManager.reset!
      end

      describe '#name' do
        it 'shows the stack name' do
          expect(stack.name).to eq(stack_name)
        end
      end

      describe '#path' do
        it 'shows the full stack path' do
          expect(stack.path).to eq("#{config.base_folder}/#{stack_name}")
        end
      end

      context 'with custom install_dir' do
        before(:each) do
          @temp_dir = Dir.mktmpdir('terradactyl')
          stack.config.terraform.install_dir = @temp_dir
        end

        after(:each) do
          FileUtils.rm_rf @temp_dir
          stack.config.reload
        end

        describe '#init' do
          context 'without autoinstall' do
            it 'fails to execute' do
              stack.config.terraform.autoinstall = false
              expect { stack.init }.to raise_error(
                inventory_error, /#{inventory_error_msg}/)
            end
          end

          context 'with autoinstall' do
            it 'executes sucessfully' do
              stack.config.terraform.autoinstall = true
              expect(stack.init).to be_zero
              expect(File.exist?(tf_binary)).to be_truthy
              expect(Dir.exist?(artifacts.init)).to be_truthy
            end
          end
        end
      end

      context 'when verbosity and debug are false' do
        after(:each) do
          artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
        end

        describe '#init' do
          it 'inits the target stack' do
            expect(stack.init).to be_zero
            expect(Dir.exist?(artifacts.init)).to be_truthy
          end
        end

        describe '#plan' do
          it 'plans the target stack' do
            expect(stack.init).to be_zero
            expect(Dir.exist?(artifacts.init)).to be_truthy

            expect(stack.plan).to eq(2)
            expect(File.exist?(artifacts.plan)).to be_truthy
            expect(File.exist?(artifacts.plan_file_obj)).to be_truthy
          end
        end

        describe '#apply' do
          it 'applies the target stack' do
            expect(stack.init).to be_zero
            expect(Dir.exist?(artifacts.init)).to be_truthy

            expect(stack.plan).to eq(2)
            expect(File.exist?(artifacts.plan)).to be_truthy

            expect(stack.apply).to eq(0)
            expect(File.exist?(artifacts.apply)).to be_truthy
          end
        end

        describe '#refresh' do
          it 'refreshes state on the target stack' do
            expect(stack.init).to be_zero
            expect(Dir.exist?(artifacts.init)).to be_truthy

            expect(stack.plan).to eq(2)
            expect(File.exist?(artifacts.plan)).to be_truthy

            expect(stack.apply).to eq(0)
            expect(File.exist?(artifacts.apply)).to be_truthy

            expect(stack.refresh).to eq(0)
            expect(File.exist?(artifacts.destroy)).to be_truthy
          end
        end

        describe '#destroy' do
          it 'destroys the target stack' do
            expect(stack.init).to be_zero
            expect(Dir.exist?(artifacts.init)).to be_truthy

            expect(stack.plan).to eq(2)
            expect(File.exist?(artifacts.plan)).to be_truthy

            expect(stack.apply).to eq(0)
            expect(File.exist?(artifacts.apply)).to be_truthy

            expect(stack.refresh).to eq(0)
            expect(File.exist?(artifacts.refresh)).to be_truthy
            expect(FileUtils.rm(artifacts.refresh)).to be_truthy

            expect(stack.destroy).to eq(0)
            expect(File.exist?(artifacts.destroy)).to be_truthy
          end
        end
      end

      context 'when echo is true' do
        after(:each) do
          artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
          config.reload
        end

        it 'echoes the Terraform shell commands' do
          config.terraform.echo = true
          expect { stack.init }.to output(/.*terraform.*init.*/).to_stdout
          expect { stack.plan }.to output(/.*terraform.*plan.*/).to_stdout
          expect { stack.apply }.to output(/.*terraform.*apply.*/).to_stdout
          expect { stack.refresh }.to output(/.*terraform.*refresh.*/).to_stdout
          expect { stack.destroy }.to output(/.*terraform.*destroy.*/).to_stdout
        end
      end

      context 'when quiet is false' do
        after(:each) do
          artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
          config.reload
        end

        it 'prints Terraform output' do
          config.terraform.quiet = false
          expect { stack.init }.to output(/Initializing provider plugins/).to_stdout
        end

        it 'prints Terradactyl output' do
          config.terraform.quiet = false
          silence { stack.init }
          expect { stack.clean }.to output(/\* Removing: \.terraform/).to_stdout
        end
      end

      context 'code validation operations' do
        before(:each) do
          stack.init
        end

        after(:each) do
          config.reload
        end

        describe '#validate' do
          before do
            File.write(artifacts.validate, invalid)
          end

          after do
            artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
          end

          it 'finds invalid stack code' do
            silence { expect(stack.validate).not_to eq(0) }
          end
        end
      end

      context 'code formatting operations' do
        before(:each) do
          File.write(artifacts.lint, unlinted)
        end

        after(:each) do
          artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
          config.reload
        end

        describe '#lint' do
          it 'finds unformatted stack code' do
            expect(stack.lint).not_to eq(0)
          end
        end

        describe '#fmt' do
          it 'reformats stack code' do
            expect(File.read(artifacts.lint)).to eq(unlinted)
            expect(stack.fmt).to eq(0)
            expect(File.read(artifacts.lint)).not_to eq(unlinted)
          end
        end
      end

      context 'when there is a plan file in the stack' do
        before(:each) do
          silence {
            stack.init
            stack.plan
          }
        end

        after(:each) do
          silence {
            artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
            config.reload
          }
        end

        describe '#plan_file_obj' do
          it 'returns a PlanFile object' do
            expect(stack.plan_file_obj).to be_a(Terradactyl::Terraform::PlanFile)
          end
        end

        describe '#planned?' do
          it 'checks for presence of a plan file' do
            expect(stack.planned?).to be_truthy
          end
        end

        describe '#print_plan' do
          it 'displays the Terraform plan output' do
            expect { stack.print_plan }.to output(/#{plan_file_signature}/).to_stdout
          end
        end

        describe '#remove_plan_file' do
          it 'removes the existing plan file from the stack' do
            silence do
              expect(stack.remove_plan_file).to be_truthy
            end
            expect(File.exist?(artifacts.plan)).to be_falsey
          end
        end

        describe '#clean' do
          it 'removes plan artifacts' do
            silence do
              expect(stack.clean).to be_nil
            end
            artifacts.each_pair do |_k, f|
              expect(File.exist?(f)).to be_falsey
            end
          end
        end
      end
    end
  end
end
