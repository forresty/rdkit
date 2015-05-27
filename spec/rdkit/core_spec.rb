require 'spec_helper'

module RDKit
  describe Core do
    it { is_expected.to respond_to :introspection }
    it { is_expected.to respond_to :tick! }

    describe '#introspection' do
      it 'raises NotImplementedError' do
        expect { subject.introspection }.to raise_exception(ShouldOverrideError)
      end
    end

    describe 'class methods' do
      subject { Core }

      it { is_expected.to respond_to :instance }
    end
  end
end
