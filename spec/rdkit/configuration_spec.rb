require "spec_helper"

module RDKit
  describe Configuration do
    describe 'class methods' do
      subject { Configuration }

      it { is_expected.to respond_to :get }
      it { is_expected.to respond_to :get_i }
      it { is_expected.to respond_to :set }

      before(:each) { subject.reset }

      describe 'get and set' do
        it 'just works' do
          expect(subject.get('slowlog-log-slower-than')).to be_nil
          subject.set('slowlog-log-slower-than', 10)
          expect(subject.get('slowlog-log-slower-than')).to eq(10)
        end
      end

      describe '#get_i' do
        it 'return -1 for nil' do
          expect(subject.get('slowlog-log-slower-than')).to be_nil
          expect(subject.get_i('slowlog-log-slower-than')).to eq(-1)
        end

        it 'converts to int' do
          expect(subject.get('slowlog-log-slower-than')).to be_nil
          subject.set('slowlog-log-slower-than', "10")
          expect(subject.get_i('slowlog-log-slower-than')).to eq(10)
        end
      end
    end
  end
end
