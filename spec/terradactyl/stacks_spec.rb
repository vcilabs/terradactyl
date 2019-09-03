require 'spec_helper'

RSpec.describe Terradactyl::Stacks do
  let(:stack_name) { 'stack_a' }
  let(:stack)      { Terradactyl::Stack.new(stack_name) }
  let(:config)     { stack.config }
  let(:artifacts)  { terraform_build_artifacts(stack) }

  before(:each) do
    Terradactyl::Terraform::VersionManager.binaries.each do |path|
      FileUtils.rm path
    end
  end

  after(:all) do
    Terradactyl::Terraform::VersionManager.binaries.each do |path|
      FileUtils.rm path
    end
  end

  context 'instance methods' do
    after(:each) do
      artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
    end

    describe '#list' do
      it 'displays a list of Terraform stacks' do
        expect(subject.list).to be_a(Array)
        expect(subject.list.size).to eq(3)
      end
    end

    describe '#validate' do
      context 'when the specifed stack exists' do
        it 'returns true' do
          expect(subject.validate('stack_a')).to be_truthy
        end
      end
      context 'when the specifed stack does NOT exist' do
        it 'returns true' do
          expect(subject.validate('foo')).to be_falsey
        end
      end
    end

    describe '#size' do
      it 'displays the num of stacks' do
        expect(subject.size).to eq(3)
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

    after(:each) do
      artifacts.each_pair { |_k,v| FileUtils.rm_rf(v) if File.exist?(v) }
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
end
