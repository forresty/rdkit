require "spec_helper"

module RDKit
  describe RESPRunner do
    it { is_expected.to respond_to :resp }

    it { is_expected.to respond_to :info }
    it { is_expected.to respond_to :ping }
    it { is_expected.to respond_to :select }
    it { is_expected.to respond_to :echo }
    it { is_expected.to respond_to :time }
    it { is_expected.to respond_to :config }
    it { is_expected.to respond_to :slowlog }

    describe '#resp' do
      it 'generates RESP response' do
        expect(subject.resp('PING')).to match(/PONG/)
      end
    end

    describe '#call' do
      it 'raise UnknownCommandError on obscure command' do
        expect { subject.__send__(:call, 'xx') }.to raise_exception(UnknownCommandError)
      end
    end
  end
end
