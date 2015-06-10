require "spec_helper"

module RDKit
  describe DB do
    it { is_expected.to respond_to :index }
  end
end
