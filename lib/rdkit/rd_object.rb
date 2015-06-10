module RDKit
  class RDObject
    attr_accessor :type, :encoding, :value

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
    end

    class << self; include ClassMethods; end
  end

  class RDList < RDObject
    def unshift(*elements)
      value.unshift(*elements)
    end

    def length
      value.length
    end
  end
end
