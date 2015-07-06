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

    it 'handles long commands' do
      subject.feed("*81\r\n$3\r\nadd\r\n$7\r\n1177395\r\n$3\r\n749\r\n$3\r\n922\r\n$3\r\n940\r\n$3\r\n996\r\n$4\r\n1102\r\n$4\r\n1171\r\n$4\r\n1220\r\n$7\r\n1000276\r\n$7\r\n1000300\r\n$7\r\n1000997\r\n$7\r\n1001125\r\n$7\r\n1001380\r\n$7\r\n1001617\r\n$7\r\n1002094\r\n$7\r\n1002197\r\n$7\r\n1002269\r\n$7\r\n1002520\r\n$7\r\n1002614\r\n$7\r\n1002649\r\n$7\r\n1002782\r\n$7\r\n1003399\r\n$7\r\n1003638\r\n$7\r\n1004209\r\n$7\r\n1005513\r\n$7\r\n1005858\r\n$7\r\n1006967\r\n$7\r\n1007387\r\n$7\r\n1007982\r\n$7\r\n1009659\r\n$7\r\n1010182\r\n$7\r\n1011074\r\n$7\r\n1012089\r\n$7\r\n1013339\r\n$7\r\n1013355\r\n$7\r\n1015144\r\n$7\r\n1017246\r\n$7\r\n1017251\r\n$7\r\n1018809\r\n$7\r\n1018986\r\n$7\r\n1019927\r\n$7\r\n1020834\r\n$7\r\n1021495\r\n$7\r\n1022945\r\n$7\r\n1023537\r\n$7\r\n1025629\r\n$7\r\n1026578\r\n$7\r\n1029873\r\n$7\r\n1029954\r\n$7\r\n1034353\r\n$7\r\n1034723\r\n$7\r\n1039916\r\n$7\r\n1052265\r\n$7\r\n1055027\r\n$7\r\n1057187\r\n$7\r\n1062532\r\n$7\r\n1068778\r\n$7\r\n1076851\r\n$7\r\n1083341\r\n$7\r\n1083677\r\n$7\r\n1089709\r\n$7\r\n1090824\r\n$7\r\n1103071\r\n$7\r\n1127902\r\n$7\r\n1136416\r\n$7\r\n1141671\r\n$7\r\n1164170\r\n$7\r\n1168407\r\n$7\r\n1170635\r\n$7\r\n1174127\r\n$7\r\n1175089\r\n$7\r\n1187961\r\n$7\r\n1194786\r\n$7\r\n1197161\r\n$7\r\n1212189\r\n$7\r\n1218095\r\n$7\r\n1220254\r\n$7\r\n1230195\r\n$7\r\n1234027\r\n$7\r\n1236")
      expect(subject.gets).to eq(false)

      subject.feed("557\r\n")
      expect(subject.gets).to eq(%w{ add 1177395 749 922 940 996 1102 1171 1220 1000276 1000300 1000997 1001125 1001380 1001617 1002094 1002197 1002269 1002520 1002614 1002649 1002782 1003399 1003638 1004209 1005513 1005858 1006967 1007387 1007982 1009659 1010182 1011074 1012089 1013339 1013355 1015144 1017246 1017251 1018809 1018986 1019927 1020834 1021495 1022945 1023537 1025629 1026578 1029873 1029954 1034353 1034723 1039916 1052265 1055027 1057187 1062532 1068778 1076851 1083341 1083677 1089709 1090824 1103071 1127902 1136416 1141671 1164170 1168407 1170635 1174127 1175089 1187961 1194786 1197161 1212189 1218095 1220254 1230195 1234027 1236557 })
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


    describe 'mix matching' do
      it 'allows mix matching' do
        skip 'not sure whether we should support this any more'

        subject.feed("PING\r\n")
        expect(subject.gets).to eq(['PING'])

        subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
        expect(subject.gets).to eq(["LLEN", "mylist"])

        subject.feed("EXISTS somekey\r\n")
        expect(subject.gets).to eq(['EXISTS', 'somekey'])

        subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
        expect(subject.gets).to eq(["LLEN", "mylist"])
      end

      it 'has internal buffer' do
        skip 'not sure whether we should support this any more'

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
        skip 'not sure whether we should support this any more'

        subject.feed("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
        subject.feed("PING\r\n")

        expect(subject.gets).to eq(["LLEN", "mylist"])
        expect(subject.gets).to eq(['PING'])
        expect(subject.gets).to eq(false)
      end
    end
  end
end
