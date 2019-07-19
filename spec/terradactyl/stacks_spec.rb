require 'spec_helper'

RSpec.describe Terradactyl::Stacks do

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
