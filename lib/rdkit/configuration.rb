module RDKit
  class Configuration
    attr_reader :config

    def initialize
      @config = {}
    end

    module ClassMethods
      @@instance = Configuration.new

      def reset
        @@instance = Configuration.new
      end

      def get(key)
        @@instance.config[key]
      end

      def get_i(key)
        @@instance.config[key] ? @@instance.config[key].to_i : -1
      end

      def set(key, value)
        @@instance.config[key] = value
      end
    end

    class << self; include ClassMethods; end
  end
end
