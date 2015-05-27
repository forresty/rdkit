require "spec_helper"

module RDKit
  describe RESPRunner do
    it { is_expected.to respond_to :resp }

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
