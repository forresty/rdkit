require 'spec_helper'

module RDKit
  describe Core do
    it { is_expected.to respond_to :tick! }
  end
end
