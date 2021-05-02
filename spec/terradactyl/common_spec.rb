require 'spec_helper'

RSpec.describe Terradactyl::Common do
  describe '#required_versions_re' do
    it 'will match a Terraform required_versions setting' do
      expect(subject.required_versions_re).to be_a(Regexp)
      expect('required_version = "~> 0.12.31"').to match(subject.required_versions_re)
    end
  end

  describe '#supported_revisions' do
    it 'returns a list of support Terraform revisions' do
      expect(subject.supported_revisions).to be_a(Array)
      expect(subject.supported_revisions.first.to_s).to match(/Rev/)
    end
  end

  describe '#config' do
    it 'initializes the Config object' do
      expect(subject.config).to be_a(Terradactyl::ConfigProject)
    end
  end

  describe '#terraform_binary' do
    it 'returns the path to the terraform executable' do
      expect(subject.terraform_binary).to eq('terraform')
    end
  end

  describe '#tag' do
    it 'returns the tag used in print statements' do
      expect(subject.tag).to eq('Terradactyl')
    end
  end

  describe '#border' do
    it 'creates a border string of hashmarks' do
      expect(subject.border).to eq('#' * 80)
    end
  end

  describe '#centre' do
    it 'calculates the centre' do
      expect(subject.centre).to eq(40)
    end
  end

  describe '#dot_icon' do
    context 'when UTF-8 is enabled' do
      it 'produces a fancy dot' do
        subject.config.misc.utf8 = true
        expect(subject.dot_icon).to eq('•')
      end
    end
    context 'when UTF-8 is enabled' do
      it 'produces a plain dot' do
        subject.config.misc.utf8 = false
        expect(subject.dot_icon).to eq('*')
      end
    end
  end

  describe '#stack_icon' do
    context 'when UTF-8 is enabled' do
      it 'produces a fancy icon' do
        subject.config.misc.utf8 = true
        expect(subject.stack_icon).to eq("  𝓣  ")
      end
    end
    context 'when UTF-8 is enabled' do
      it 'produces a plain icon' do
        subject.config.misc.utf8 = false
        expect(subject.stack_icon).to eq("  |||  ")
      end
    end
  end

  describe '#print_crit' do
    it 'outputs text' do
      expect { subject.print_crit("FOO") }.to output(/FOO/).to_stdout
    end
  end

  describe '#print_ok' do
    it 'outputs text' do
      expect { subject.print_ok("FOO") }.to output(/FOO/).to_stdout
    end
  end

  describe '#print_warning' do
    it 'outputs text' do
      expect { subject.print_warning("FOO") }.to output(/FOO/).to_stdout
    end
  end

  describe '#print_dot' do
    it 'outputs text' do
      expect { subject.print_dot("FOO") }.to output(/FOO/).to_stdout
    end
  end

  describe '#print_content' do
    it 'outputs text' do
      expect { subject.print_content("FOO") }.to output(/FOO/).to_stdout
    end
  end

  describe '#print_line' do
    it 'outputs text' do
      expect { subject.print_line("FOO") }.to output(/FOO/).to_stdout
    end
  end

  describe '#print_message' do
    it 'outputs text' do
      expect { subject.print_message("FOO") }.to output(/FOO/).to_stdout
    end
  end

  describe '#print_header' do
    it 'outputs text' do
      expect { subject.print_header("FOO") }.to output(/FOO/).to_stdout
    end
  end

end
