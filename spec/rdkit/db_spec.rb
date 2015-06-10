require "spec_helper"

module RDKit
  describe DB do
    it { is_expected.to respond_to :index }
    it { is_expected.to respond_to :get }
    it { is_expected.to respond_to :set }
  end
end
