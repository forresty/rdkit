require "spec_helper"

module RDKit
  describe Introspection::Commandstats do
    describe 'class methods' do
      subject { Introspection::Commandstats }

      describe '.info' do
        it 'generates a hash' do
          subject.record('ping', 9)
          subject.record('ping', 10)
          subject.record('info', 21)

          expected = [
            ['comstat_info', 'calls=1,usec=21,usec_per_call=21.00'],
            ['comstat_ping', 'calls=2,usec=19,usec_per_call=9.50']
          ]

          expect(subject.info).to eq(expected)
        end
      end
    end
  end
end
