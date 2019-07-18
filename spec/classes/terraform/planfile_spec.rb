require 'spec_helper'

RSpec.describe Terradactyl::Terraform::PlanFile do

  let(:stack_name) { 'stack_b' }
  let(:stack)      { Terradactyl::Stack.new(stack_name) }
  let(:stack_path) { "#{stack.path}/#{stack_name}.tfout" }
  let(:config)     { stack.config }

  before(:each) do
    silence {
      config.reload
      stack.init
      stack.plan
    }
  end

  after(:each) do
    silence { stack.clean }
  end

  context 'initialization' do
    describe '#load' do
      it 'loads and parses a terraform plan file' do
        expect(described_class.load(stack_path)).to be_a(described_class)
        expect(described_class.load(stack_path)).to respond_to(:checksum)
      end
    end
  end

  context 'initialized' do

    let(:instance) { described_class.load(stack_path) }

    describe '#checksum' do
      let(:sha1sum_re) { /(?:[0-9a-f]){40}/ }
      it 'emits a checksum of the plan content' do
        expect(instance.checksum).to match(/#{sha1sum_re}/)
      end
    end

    describe '#to_markdown' do
      let(:markdown)    { instance.to_markdown }
      let(:markdown_re) { %r{#### #{stack_name}} }
      it 'emits plan formatted as markdown' do
        expect(markdown).to match(/#{markdown_re}/)
      end
    end
  end

end
