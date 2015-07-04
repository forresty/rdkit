require "spec_helper"

module RDKit
  describe RESPParser do
    it 'handles normal commands' do
      subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
      expect(subject.gets).to eq(["LLEN", "mylist"])
    end

    it 'handles inline commands' do
      subject.feed("PING\r\n")
      expect(subject.gets).to eq(['PING'])

      subject.feed("EXISTS somekey\r\n")
      expect(subject.gets).to eq(['EXISTS', 'somekey'])
    end

    it 'allows mix matching' do
      subject.feed("PING\r\n")
      expect(subject.gets).to eq(['PING'])

      subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
      expect(subject.gets).to eq(["LLEN", "mylist"])

      subject.feed("EXISTS somekey\r\n")
      expect(subject.gets).to eq(['EXISTS', 'somekey'])

      subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
      expect(subject.gets).to eq(["LLEN", "mylist"])
    end

    it 'raises error on illegal inline command' do
      subject.feed("PING")
      expect { subject.gets }.to raise_exception
    end

    it 'handle repeat read on inline command as well' do
      subject.feed("PING\r\n")
      expect(subject.gets).to eq(['PING'])
      expect(subject.gets).to eq(false)
    end

    it 'has internal buffer' do
      subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
      subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")

      expect(subject.gets).to eq(["LLEN", "mylist"])
      expect(subject.gets).to eq(["LLEN", "mylist"])
      expect(subject.gets).to eq(false)

      subject.feed("PING\r\n")
      subject.feed("SELECT 0\r\n")

      expect(subject.gets).to eq(['PING'])
      expect(subject.gets).to eq(['SELECT', '0'])
      expect(subject.gets).to eq(false)
    end

    it 'does not break order' do
      subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
      subject.feed("PING\r\n")

      expect(subject.gets).to eq(["LLEN", "mylist"])
      expect(subject.gets).to eq(['PING'])
      expect(subject.gets).to eq(false)
    end
  end
end
