require "spec_helper"

module RDKit
  describe 'errors' do
    it 'has default message' do
      expect { raise SyntaxError }.to raise_exception(SyntaxError, 'syntax error')

      expect {
        raise ValueNotAnIntegerOrOutOfRangeError
      }.to raise_exception(ValueNotAnIntegerOrOutOfRangeError, 'value is not an integer or out of range')
    end
  end
end
