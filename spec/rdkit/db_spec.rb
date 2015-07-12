require "spec_helper"

module RDKit
  describe DB do
    it { is_expected.to respond_to :index }
    it { is_expected.to respond_to :get }
    it { is_expected.to respond_to :set }
    it { is_expected.to respond_to :lpop }
    it { is_expected.to respond_to :rpop }
  end
end
