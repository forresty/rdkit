require "spec_helper"

module RDKit
  describe NotificationCenter do
    subject { NotificationCenter }

    it { is_expected.to respond_to :publish }
    it { is_expected.to respond_to :subscribe }
    it { is_expected.to respond_to :unsubscribe }

    describe 'pubsub' do
      it 'just works' do
        @result = nil

        subject.subscribe('foo', self) { |message| @result = message }
        subject.publish('foo', 'bar')

        expect(@result).to eq('bar')
      end

      it 'can unsub' do
        @result = nil

        subject.subscribe('foo', self) { |message| @result = message }
        subject.publish('foo', 'bar')

        expect(@result).to eq('bar')

        subject.unsubscribe('foo', self)
        subject.publish('foo', 'baz')

        expect(@result).to eq('bar')
      end

      it 'can have multiple subscribers' do
        @result1, @result2 = nil, nil

        subject.subscribe('foo', '1') { |message| @result1 = message }
        subject.subscribe('foo', '2') { |message| @result2 = message }
        subject.publish('foo', 'bar')

        expect(@result1).to eq('bar')
        expect(@result2).to eq('bar')
      end

      it 'does nothing when there is no subscribers' do
        subject.publish('foo', 'bar')
      end
    end
  end
end
