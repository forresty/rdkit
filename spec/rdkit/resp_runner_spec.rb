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

    describe '#select' do
      it 'selects DB by index' do
        expect(subject.server.current_db.index).to eq(0)

        expect { subject.select('x') }.to raise_exception(InvalidDBIndexError)
        expect { subject.select('-1') }.to raise_exception(InvalidDBIndexError)
        expect { subject.select('16') }.to raise_exception(InvalidDBIndexError)

        subject.select('15')

        expect(subject.server.current_db.index).to eq(15)
      end
    end

    describe '#set' do
      it 'sets string value' do
        expect(subject.get('foo')).to eq(nil)
        subject.set('foo', 'bar')
        expect(subject.get('foo')).to eq('bar')
      end
    end

    describe '#del' do
      it 'deletes keys' do
        subject.set('foo1', 'bar')
        subject.set('foo2', 'bar')
        subject.set('foo3', 'bar')

        expect(subject.del('foo2', 'foo3', 'foo4')).to eq(2)
        expect(subject.del('foo2', 'foo3', 'foo4')).to eq(0)
        expect(subject.get('foo2')).to eq(nil)
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
