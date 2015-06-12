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
    it { is_expected.to respond_to :get }
    it { is_expected.to respond_to :set }
    it { is_expected.to respond_to :del }
    it { is_expected.to respond_to :keys }
    it { is_expected.to respond_to :lpush }
    it { is_expected.to respond_to :llen }

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

    describe '#mget' do
      it 'returns nil when not found' do
        subject.set('foo2', 'bar')

        expect(subject.mget('foo1', 'foo2', 'foo3')).to eq([nil, 'bar', nil])
      end

      it 'returns nil on WRONTYPEd objects' do
        subject.set('foo2', 'bar')
        subject.lpush('foo1', '1')

        expect(subject.mget('foo1', 'foo2', 'foo3')).to eq([nil, 'bar', nil])
      end
    end

    describe '#mset' do
      it 'requires right number of args' do
        expect { subject.__send__(:call, 'mset') }.to raise_exception(WrongNumberOfArgumentError)
        expect { subject.__send__(:call, ['mset', 'a']) }.to raise_exception(WrongNumberOfArgumentError)
        expect { subject.__send__(:call, ['mset', 'a', 'b', 'c']) }.to raise_exception(WrongNumberOfArgumentError)
      end

      it 'sets values' do
        subject.mset('foo1', 'bar1')
        subject.mset('foo2', 'bar2', 'foo3', 'bar3', 'foo4', 'bar4')

        expect(subject.mget('foo1', 'foo2', 'foo3', 'foo4')).to eq(%w{ bar1 bar2 bar3 bar4 })
      end
    end

    describe '#strlen' do
      it 'returns bytesize' do
        expect(subject.strlen('a')).to eq(0)
        subject.set('a', 'hello')
        expect(subject.strlen('a')).to eq(5)

        subject.set('a', '中国') # UTF-8
        expect(subject.strlen('a')).to eq(6)

        subject.lpush('b', '1')
        expect { subject.__send__(:call, ['strlen', 'b']) }.to raise_exception(WrongTypeError)
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

      it 'does not allow empty args' do
        expect { subject.__send__(:call, 'del') }.to raise_exception(WrongNumberOfArgumentError)
      end
    end

    describe '#exists' do
      it 'tests if key exists' do
        expect(subject.exists('key')).to eq(false)
        subject.set('key', 'value')
        expect(subject.exists('key')).to eq(true)
      end
    end

    describe '#lrange' do
      skip 'not implemented yet'
    end

    describe '#scard' do
      it 'returns size of the set' do
        subject.sadd('key', 'a', 'b', 'c', 'c')
        expect(subject.scard('key')).to eq(3)
      end
    end

    describe '#srem' do
      it 'removes the set when it is empty' do
        subject.sadd('key', 'a', 'b')
        expect(subject.scard('key')).to eq(2)
        expect(subject.srem('key', 'a', 'b')).to eq(2)
        expect(subject.scard('key')).to eq(0)
        expect(subject.exists('key')).to eq(false)
      end
    end

    describe '#hdel' do
      it 'removes the hash when it is empty' do
        subject.hset('key', 'field', 'value')
        expect(subject.hlen('key')).to eq(1)
        expect(subject.hdel('key', 'field')).to eq(1)
        expect(subject.hlen('key')).to eq(0)
        expect(subject.exists('key')).to eq(false)
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
