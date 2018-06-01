module Terradactyl

  class Config

    include Singleton

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

    private

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