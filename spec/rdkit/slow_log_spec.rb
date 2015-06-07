require "spec_helper"

module RDKit
  describe SlowLog do
    describe 'class methods' do
      subject { SlowLog }

      it { is_expected.to respond_to :monitor }
      it { is_expected.to respond_to :recent }
    end
  end
end
