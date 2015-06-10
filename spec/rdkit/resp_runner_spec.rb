require "spec_helper"

module RDKit
  describe RESPRunner do
    let(:server) { Server.new('0.0.0.0', 3721) }

    subject { RESPRunner.new(server) }

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

      it 'generate RESP error on exception' do
        expect(subject.resp('xx')).to match(/unknown command/)
      end
    end

    describe '#echo' do
      it 'echo' do
        expect(subject.echo('haha')).to eq('haha')
      end
    end

    describe '#time' do
      it 'returns server time' do
        Timecop.freeze do
          expect(subject.time).to eq([Time.now.to_i, Time.now.usec].map(&:to_s))
        end
      end
    end

    describe '#call' do
      it 'raise UnknownCommandError on obscure command' do
        expect { subject.__send__(:call, 'xx') }.to raise_exception(UnknownCommandError)
      end

      it 'raise WrongNumberOfArgumentError when it should' do
        expect { subject.__send__(:call, %w{ ping pong }) }.to raise_exception(WrongNumberOfArgumentError)
      end
    end
  end
end
