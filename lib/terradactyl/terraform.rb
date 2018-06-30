module Terradactyl

  class TerraformPlan

    attr_reader :data, :summary, :file_name, :base_folder, :stack_name

    def self.load(plan_path)
      new plan_path
    end

    def initialize(plan_path)
      @add, @change, @destroy = 0, 0, 0
      @file_name              = File.basename(plan_path)
      @stack_name             = File.basename(plan_path, '.tfout')
      @base_folder            = File.dirname(plan_path).split('/')[-2]
      @data                   = read_plan(plan_path)
      @summary                = generate_summary
    end

    def checksum
      Digest::SHA1.hexdigest normalize(data)
    end

    def to_markdown(base_folder=nil)
      [
        "**#{[base_folder, stack_name].compact.join('/')}**",
        '```',
        data,
        "  #{summary}",
        '```',
      ].compact.join("\n")
    end

    def to_s
      @data
    end

    def <=>(other)
      self.data <=> other.data
    end

    def normalized
      normalize(data)
    end

    def modified?
      @modified ||= ! [@add, @change, @destroy].reduce(&:+).zero?
    end

    private

    def normalize(data)
      lines = data.split("\n").inject([]) do |memo,line|
        memo << normalize_line(line); memo
      end
      lines.join("\n")
    end

    def re_json_blob
      /\"{\\n.+?\\n}\"/
    end

    def re_json_line
      /^(?<attrib>\s+\w+:\s+)(?<json>.+?#{re_json_blob}.*)/
    end

    def normalize_json(blob)
      if blob.match(re_json_blob)
        un_esc = eval(blob).chomp
        return JSON.parse(un_esc).deep_sort.to_json.inspect
      end
      blob
    end

    def normalize_line(line)
      if caps = line.match(re_json_line)
        blobs = caps['json'].split(' => ').map { |blob| normalize_json(blob) }
        blobs = blobs.join(' => ')
        line  = [caps['attrib'], %{#{blobs}}].join
      end
      line
    end

    def read_plan(plan_path)
      output = %x{TF_CLI_ARGS='' terraform show -no-color #{plan_path}}
      raise 'Error reading plan file!' unless $?.success?
      output
    end

    def generate_summary
      template = "Plan: %i to add, %i to change, %i to destroy."
      @data.each_line do |line|
        if cap = line.match(/^\s{0,2}(?<op>(?:[+-~]|-\/\+))\s/)
          case cap['op']
          when '+'
            @add += 1
          when '~'
            @change += 1
          when '-'
            @destroy += 1
          when '-/+'
            @add += 1
            @destroy += 1
          end
        end
      end
      return 'No changes. Infrastructure is up-to-date.' unless modified?
      template % [@add, @change, @destroy]
    end

  end

  class TerraformVersion

    class << self

      MIN_VERSION   = '0.9.0'
      ERROR_VERSION = 'Terraform version mismatch'
      ERROR_INSTALL = 'Terraform not installed'

      include Common

      def current
        raw = %x{#{terraform_path} version}.match(tf_raw_semver_re)
        Gem::Version.new raw['version']
      rescue
        nil
      end

      def minimum
        Gem::Version.new MIN_VERSION
      end

      def required
        Gem::Version.new config.terraform.version
      end

      def installed?
        current
      end

      def seatbelt
        raise ERROR_INSTALL unless installed?
        raise ERROR_VERSION unless (current >= minimum)
        raise ERROR_VERSION unless (current == required)
      rescue => e
        abort <<-HODOR
*** #{e.message} ***
Minimum: #{minimum} | Current: #{current} | Required: #{required}

Check your `#{Config::CONFIG_FILE}` and ensure that both the config
and your installed Terraform binary meet the requirements.
HODOR
      end

      private

      def tf_raw_semver_re
        /^Terraform\s+v(?<version>(\d+\.\d+\.\d+))/
      end

    end

  end

end
