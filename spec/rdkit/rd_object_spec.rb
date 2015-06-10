require "spec_helper"

module RDKit
  describe RDObject do
    it { is_expected.to respond_to :type }
    it { is_expected.to respond_to :encoding }
    it { is_expected.to respond_to :value }

    describe 'class methods' do
      subject { RDObject }

      describe '.string' do
        it 'creates string object' do
          expect(subject.string('haha').type).to eq(:string)
        end
      end
    end
  end
end
