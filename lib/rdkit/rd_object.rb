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
    end

    class << self; include ClassMethods; end
  end
end
