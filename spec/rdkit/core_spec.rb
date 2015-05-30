require 'spec_helper'

module RDKit
  describe Core do
    it { is_expected.to respond_to :tick! }

    describe 'class methods' do
      subject { Core }

      it { is_expected.to respond_to :instance }
    end
  end
end
