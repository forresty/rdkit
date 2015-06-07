module RDKit
  class Configuration
    attr_reader :config

    def initialize
      @config = {}
    end

    module ClassMethods
      @@instance = Configuration.new

      def get(key)
        @@instance.config[key]
      end

      def set(key, value)
        @@instance.config[key] = value
      end
    end

    class << self; include ClassMethods; end
  end
end
