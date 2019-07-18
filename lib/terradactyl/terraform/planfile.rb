module Terradactyl

  module Terraform

    class PlanFile

      attr_reader :data, :summary, :file_name, :base_folder, :stack_name,
                  :options

      def self.load(plan_path, options: nil)
        new(plan_path, options: options)
      end

      def initialize(plan_path, options: nil)
        @add, @change, @destroy = 0, 0, 0
        @options                = options || Commands::Options.new
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
          "#### #{[base_folder, stack_name].compact.join('/')}",
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
      rescue JSON::ParserError
        line
      end

      def read_plan(plan_path)
        options.environment = {}
        options.no_color = true unless ENV['TF_CLI_ARGS'] =~ /-no-color/
        captured = Commands::Show.execute(dir_or_plan: plan_path,
                                          options: options,
                                          capture: true)
        raise 'Error reading plan file!' unless captured.exitstatus.zero?
        captured.stdout
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

  end

end
