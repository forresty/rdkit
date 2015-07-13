require 'spec_helper'

module RDKit
  describe Server do
    subject { Server.new('0.0.0.0', 3721) }

    it { is_expected.to respond_to :current_client }
    it { is_expected.to respond_to :current_db }
    it { is_expected.to respond_to :blocking }
    it { is_expected.to respond_to :server_started }
    it { is_expected.to respond_to :client_connected }
    it { is_expected.to respond_to :client_blocked }

    describe 'class methods' do
      subject { Server }

      it { is_expected.to respond_to :register }
      it { is_expected.to respond_to :instance }
    end
  end
end
