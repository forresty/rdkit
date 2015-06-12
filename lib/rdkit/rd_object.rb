module RDKit
  class RDObject
    attr_accessor :type, :encoding, :value

    def self.forward_to_value(*methods)
      @forwarded_methods = methods
    end

    def method_missing(method, *args)
      if forwarded_methods.include?(method)
        value.__send__(method, *args)
      else
        super
      end
    end

    private

    def forwarded_methods
      self.class.instance_variable_get(:@forwarded_methods) || []
    end

    module ClassMethods
      def string(value)
        new.tap do |object|
          object.type = :string
          object.value = value
        end
      end

      def list(elements)
        RDList.new.tap do |object|
          object.type = :list
          object.value = elements
        end
      end

      def set(elements)
        require "set"

        RDSet.new.tap do |set|
          set.type = :set
          set.value = Set.new(elements)
        end
      end

      def create_hash(key, value)
        RDHash.new.tap do |hash|
          hash.type  = :hash
          hash.value = { key => value }
        end
      end
    end

    class << self; include ClassMethods; end
  end

  class RDList < RDObject
    forward_to_value :unshift, :length
  end

  class RDSet < RDObject
    forward_to_value :add, :size, :to_a, :include?, :delete
  end

  class RDHash < RDObject
    forward_to_value :has_key?, :[]=, :[], :size, :delete, :keys, :values
  end
end
