module RDKit
  module Inheritable
    def self.included(base)
      base.instance_eval do
        def instance(*args)
          @subclass.new(*args)
        end

        def inherited(klass)
          @subclass = klass
        end
      end
    end
  end
end
