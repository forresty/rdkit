require "spec_helper"

module RDKit
  describe RESP do
    subject { RESP }
    it { is_expected.to respond_to :compose }

    describe '.compose' do
      it 'transforms OK to simple string' do
        expect(subject.compose("OK")).to eq("+OK\r\n")
      end

      it 'composes booleans' do
        expect(subject.compose(true)).to eq(":1\r\n")
        expect(subject.compose(false)).to eq(":0\r\n")
      end

      it 'composes Integer' do
        expect(subject.compose(1)).to eq(":1\r\n")
      end

      it 'composes strings' do
        expect(subject.compose('haha')).to eq("$4\r\nhaha\r\n")
      end

      it 'composes errors' do
        error = ArgumentError.new('not found')
        expect(subject.compose(error)).to eq("-ERR not found\r\n")
      end

      it 'composes empty array' do
        expect(subject.compose([])).to eq("*0\r\n")
      end

      it 'composes array' do
        expect(subject.compose(['foo', 'bar'])).to eq("*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n")
      end

      it 'composes array of integers' do
        expect(subject.compose([1, 2, 3])).to eq("*3\r\n:1\r\n:2\r\n:3\r\n")
      end

      it 'composes array of mix-typed elements' do
        transformation = {
          ['Foo', StandardError.new('Bar')] => "*2\r\n$3\r\nFoo\r\n-ERR Bar\r\n",
          [1, 2, 3, 4, 'foobar'] => "*5\r\n:1\r\n:2\r\n:3\r\n:4\r\n$6\r\nfoobar\r\n"
        }

        transformation.each do |original, expected|
          expect(subject.compose(original)).to eq(expected)
        end
      end

      it 'composes nil array' do
        expect(subject.compose(nil)).to eq("$-1\r\n")
      end

      it 'composes array of arrays' do
        data = [[1, 2, 3], ['Foo', StandardError.new('Bar')]]
        expected = "*2\r\n*3\r\n:1\r\n:2\r\n:3\r\n*2\r\n$3\r\nFoo\r\n-ERR Bar\r\n"

        expect(subject.compose(data)).to eq(expected)
      end

      it 'composes array with nil elements' do
        data = ["foo",nil,"bar"]
        expected = "*3\r\n$3\r\nfoo\r\n$-1\r\n$3\r\nbar\r\n"

        expect(subject.compose(data)).to eq(expected)
      end

      it 'handles Chinese characters' do
        expect(subject.compose('中文')).to eq("$6\r\n\xE4\xB8\xAD\xE6\x96\x87\r\n")
      end
    end
  end
end
