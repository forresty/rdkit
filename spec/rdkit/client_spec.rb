require 'spec_helper'

module RDKit
  describe Client do
    let(:server) { Server.new('0.0.0.0', 3721) }

    subject { Client.new(nil, server) }

    it { is_expected.to respond_to :resume }
  end
end
