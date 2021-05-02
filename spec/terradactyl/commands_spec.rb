require 'spec_helper'

RSpec.describe Terradactyl::Commands do

  let(:dummy_class) { Class.new { extend Terradactyl::Commands } }

  described_class.public_instance_methods.each do |meth|
    it "responds to ##{meth}" do
      expect(dummy_class).to respond_to(meth)
    end
  end

  describe Terradactyl::Commands::Rev011 do
    let(:dummy_class) { Class.new { extend Terradactyl::Commands::Rev011 } }

    described_class.public_instance_methods.each do |meth|
      it "responds to ##{meth}" do
        expect(dummy_class).to respond_to(meth)
      end
    end
  end

  describe Terradactyl::Commands::Rev012 do
    let(:dummy_class) { Class.new { extend Terradactyl::Commands::Rev012 } }

    described_class.public_instance_methods.each do |meth|
      it "responds to ##{meth}" do
        expect(dummy_class).to respond_to(meth)
      end
    end
  end

  describe Terradactyl::Commands::Rev013 do
    let(:dummy_class) { Class.new { extend Terradactyl::Commands::Rev013 } }

    described_class.public_instance_methods.each do |meth|
      it "responds to ##{meth}" do
        expect(dummy_class).to respond_to(meth)
      end
    end
  end

  describe Terradactyl::Commands::Rev014 do
    let(:dummy_class) { Class.new { extend Terradactyl::Commands::Rev014 } }

    described_class.public_instance_methods.each do |meth|
      it "responds to ##{meth}" do
        expect(dummy_class).to respond_to(meth)
      end
    end
  end

  describe Terradactyl::Commands::Rev015 do
    let(:dummy_class) { Class.new { extend Terradactyl::Commands::Rev015 } }

    described_class.public_instance_methods.each do |meth|
      it "responds to ##{meth}" do
        expect(dummy_class).to respond_to(meth)
      end
    end
  end
end
