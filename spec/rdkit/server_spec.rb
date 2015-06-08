require 'spec_helper'

module RDKit
  describe Server do
    subject { Server.new('0.0.0.0', 3721) }

    it { is_expected.to respond_to :current_client }
  end
end
