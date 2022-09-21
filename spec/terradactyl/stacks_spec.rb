require 'spec_helper'

RSpec.describe Terradactyl::Stacks do
  let(:tmpdir)        { Dir.mktmpdir('rspec_terradactyl') }
  let(:known_stacks)  { Dir["#{tmpdir}/stacks/*"] }
  let(:num_of_stacks) { known_stacks.size }
  let(:target_stack)  { known_stacks.shuffle.first }
  let(:stack_name)    { File.basename(target_stack) }
  let(:stack)         { silence { Terradactyl::Stack.new(stack_name) } }
  let(:config)        { stack.config }

  before(:each) do
    Terradactyl::Terraform::VersionManager.binaries.each do |path|
      FileUtils.rm path
    end
    cp_fixtures(tmpdir)
    Dir.chdir(tmpdir)
  end

  after(:each) do
    Dir.chdir(original_work_dir)
  end

  after(:all) do
    Terradactyl::Terraform::VersionManager.binaries.each do |path|
      FileUtils.rm path
    end
  end

  context 'instance methods' do
    describe '#list' do
      it 'displays a list of Terraform stacks' do
        expect(subject.list).to be_a(Array)
        expect(subject.list.size).to eq(num_of_stacks)
      end
    end

    describe '#validate' do
      context 'when the specified stack exists' do
        it 'returns true' do
          expect(subject.validate(stack_name)).to be_truthy
        end
      end
      context 'when the specified stack does NOT exist' do
        it 'returns false' do
          expect(subject.validate('foo')).to be_falsey
        end
      end
    end

    describe '#size' do
      it 'displays the num of stacks' do
        expect(subject.size).to eq(num_of_stacks)
      end
    end

    describe '#each' do
      it 'returns an iterator for stacks' do
        expect(subject.each).to be_a(Enumerator)
      end
    end
  end

  context 'class methods' do
    before(:each) do
      described_class.dirty!(stack)
    end

    describe '#dirty?' do
      context 'given stack name' do
        it 'returns true' do
          expect(described_class.dirty?(stack_name)).to be_truthy
        end
      end
      context 'given stack path' do
        it 'returns true' do
          expect(described_class.dirty?("stacks/#{stack_name}")).to be_truthy
        end
      end
    end
  end

  context 'instance methods when passed base_override' do
    let(:known_stacks)  { Dir["#{tmpdir}/nested/*/"] }
    let(:overridden_stacks) { Terradactyl::Stacks.new(base_override: 'nested') }

    describe '#list' do
      it 'displays a list of Terraform stacks' do
        expect(overridden_stacks.list).to be_a(Array)
        expect(overridden_stacks.list.size).to eq(num_of_stacks)
      end
    end

    describe '#validate' do
      context 'when the specified stack exists' do
        it 'returns true' do
          expect(overridden_stacks.validate(stack_name)).to be_truthy
        end
      end
      context 'when the specified stack does NOT exist' do
        it 'returns false' do
          expect(overridden_stacks.validate('foo')).to be_falsey
        end
      end
    end

    describe '#size' do
      it 'displays the num of stacks' do
        expect(overridden_stacks.size).to eq(num_of_stacks)
      end
    end

    describe '#each' do
      it 'returns an iterator for stacks' do
        expect(overridden_stacks.each).to be_a(Enumerator)
      end
    end
  end
end
