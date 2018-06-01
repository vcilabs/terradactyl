module Terradactyl

  class Config

    include Singleton

    CLEANUP_REMOVE_EMPTY_DEFAULT = true

    CLEANUP_PATH_MATCH_DEFAULT = %w{
      *.tfstate*
      *.tfout
      *.tflock
      *.zip
      .terraform
    }

    CONFIG_FILE = 'terraform.yml'

    attr_accessor :terradactyl

    def initialize
      load_data_file
    end

    def terraform
      @terraform ||= OpenStruct.new terradactyl.terraform
    end

    def environment
      @environment ||= OpenStruct.new terradactyl.environment
    end

    def cleanup
      @cleanup ||= cleanup_config
    end

    private

    def cleanup_config
      terradactyl.cleanup = {
        match: CLEANUP_PATH_MATCH_DEFAULT,
        empty: CLEANUP_REMOVE_EMPTY_DEFAULT,
      }.merge(terradactyl.cleanup.to_h)
      OpenStruct.new terradactyl.cleanup
    end

    def load_data_file
      data = YAML.load_file CONFIG_FILE
      @terradactyl = OpenStruct.new data['terradactyl']
    end

    def method_missing(sym, *args, &block)
      terradactyl.send(sym.to_sym, *args, &block)
    rescue
      super
    end

  end

end