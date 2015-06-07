require "spec_helper"

module RDKit
  describe Configuration do
    describe 'class methods' do
      subject { Configuration }

      it { is_expected.to respond_to :get }
      it { is_expected.to respond_to :set }

      describe 'get and set' do
        it 'just works' do
          expect(subject.get('slowlog-log-slower-than')).to be_nil
          subject.set('slowlog-log-slower-than', 10)
          expect(subject.get('slowlog-log-slower-than')).to eq(10)
        end
      end
    end
  end
end
