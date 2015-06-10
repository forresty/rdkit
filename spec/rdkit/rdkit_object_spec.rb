require "spec_helper"

module RDKit
  describe RDKitObject do
    it { is_expected.to respond_to :type }
    it { is_expected.to respond_to :encoding }
  end
end
