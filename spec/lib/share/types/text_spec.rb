  require 'spec_helper'

describe Share::Types::Text do
  context "compress" do
    it "is sane" do
      def check_sanity(ops)
        described_class.compress(ops).should == ops
      end

      check_sanity []
      check_sanity [{'i' =>'blah', 'p' =>3}]
      check_sanity [{'d' =>'blah', 'p' =>3}]
      check_sanity [{'d' =>'blah', 'p' =>3}, {'i' =>'blah', 'p' =>10}]
    end

    it "compresses inserts" do
      described_class.compress([{'i' =>'abc', 'p' =>10}, {'i' =>'xyz', 'p' =>10}]).should == [{'i' =>'xyzabc', 'p' =>10}]
      described_class.compress([{'i' =>'abc', 'p' =>10}, {'i' =>'xyz', 'p' =>11}]).should == [{'i' =>'axyzbc', 'p' =>10}]
      described_class.compress([{'i' =>'abc', 'p' =>10}, {'i' =>'xyz', 'p' =>13}]).should == [{'i' =>'abcxyz', 'p' =>10}]      
    end

    it "compress deletes" do
      described_class.compress([{'d' =>'abc', 'p' =>10}, {'d' =>'xy', 'p' =>8}]).should == [{'d' =>'xyabc', 'p' =>8}]
      described_class.compress([{'d' =>'abc', 'p' =>10}, {'d' =>'xy', 'p' =>9}]).should == [{'d' =>'xabcy', 'p' =>9}]
      described_class.compress([{'d' =>'abc', 'p' =>10}, {'d' =>'xy', 'p' =>10}]).should == [{'d' =>'abcxy', 'p' =>10}]
    end

    it "does not compress sepearate deletes" do
      def check(op)
        described_class.compress(op).should == op
      end

      check [{'d' =>'abc', 'p' =>10}, {'d' =>'xyz', 'p' =>6}]
      check [{'d' =>'abc', 'p' =>10}, {'d' =>'xyz', 'p' =>11}]
    end
  end

  context "compose" do
    it "is sane" do
      described_class.compose([], []).should == []
      described_class.compose([{'i' =>'x', 'p' =>0}], []).should == [{'i' =>'x', 'p' =>0}]
      described_class.compose([], [{'i' =>'x', 'p' =>0}]).should == [{'i' =>'x', 'p' =>0}]
      described_class.compose([{'i' =>'y', 'p' =>100}], [{'i' =>'x', 'p' =>0}]).should == [{'i' =>'y', 'p' =>100}, {'i' =>'x', 'p' =>0}]
    end
  end

  context "transform" do
    it "is sane" do
      described_class.transform([], [], 'left').should == []
      described_class.transform([], [], 'right').should == []

      described_class.transform([{'i' =>'y', 'p' =>100}, {'i' =>'x', 'p' =>0}], [], 'left').should == [{'i' =>'y', 'p' =>100}, {'i' =>'x', 'p' =>0}]
      described_class.transform([], [{'i' =>'y', 'p' =>100}, {'i' =>'x', 'p' =>0}], 'right').should == []
    end

    it "inserts" do
      described_class.transform_x([{'i' =>'x', 'p' =>9}], [{'i' =>'a', 'p' =>1}]).should == [[{'i' =>'x', 'p' =>10}], [{'i' =>'a', 'p' =>1}]]
      described_class.transform_x([{'i' =>'x', 'p' =>10}], [{'i' =>'a', 'p' =>10}]).should == [[{'i' =>'x', 'p' =>10}], [{'i' =>'a', 'p' =>11}]]

      described_class.transform_x([{'i' =>'x', 'p' =>11}], [{'d' =>'a', 'p' =>9}]).should == [[{'i' =>'x', 'p' =>10}], [{'d' =>'a', 'p' =>9}]]
      described_class.transform_x([{'i' =>'x', 'p' =>11}], [{'d' =>'a', 'p' =>10}]).should == [[{'i' =>'x', 'p' =>10}], [{'d' =>'a', 'p' =>10}]]
      described_class.transform_x([{'i' =>'x', 'p' =>11}], [{'d' =>'a', 'p' =>11}]).should == [[{'i' =>'x', 'p' =>11}], [{'d' =>'a', 'p' =>12}]]

      described_class.transform([{'i' =>'x', 'p' =>10}], [{'d' =>'a', 'p' =>11}], 'left').should == [{'i' =>'x', 'p' =>10}]
      described_class.transform([{'i' =>'x', 'p' =>10}], [{'d' =>'a', 'p' =>10}], 'left').should == [{'i' =>'x', 'p' =>10}]
      described_class.transform([{'i' =>'x', 'p' =>10}], [{'d' =>'a', 'p' =>10}], 'right').should == [{'i' =>'x', 'p' =>10}]
    end

    it "deletes" do
      described_class.transform_x([{'d' =>'abc', 'p' =>10}], [{'d' =>'xy', 'p' =>4}]).should == [[{'d' =>'abc', 'p' =>8}], [{'d' =>'xy', 'p' =>4}]]
      described_class.transform_x([{'d' =>'abc', 'p' =>10}], [{'d' =>'b', 'p' =>11}]).should == [[{'d' =>'ac', 'p' =>10}], []]
      described_class.transform_x([{'d' =>'b', 'p' =>11}], [{'d' =>'abc', 'p' =>10}]).should == [[], [{'d' =>'ac', 'p' =>10}]]
      described_class.transform_x([{'d' =>'abc', 'p' =>10}], [{'d' =>'bc', 'p' =>11}]).should == [[{'d' =>'a', 'p' =>10}], []]
      described_class.transform_x([{'d' =>'abc', 'p' =>10}], [{'d' =>'ab', 'p' =>10}]).should == [[{'d' =>'c', 'p' =>10}], []]
      described_class.transform_x([{'d' =>'abc', 'p' =>10}], [{'d' =>'bcd', 'p' =>11}]).should == [[{'d' =>'a', 'p' =>10}], [{'d' =>'d', 'p' =>10}]]
      described_class.transform_x([{'d' =>'bcd', 'p' =>11}], [{'d' =>'abc', 'p' =>10}]).should == [[{'d' =>'d', 'p' =>10}], [{'d' =>'a', 'p' =>10}]]
      described_class.transform_x([{'d' =>'abc', 'p' =>10}], [{'d' =>'xy', 'p' =>13}]).should == [[{'d' =>'abc', 'p' =>10}], [{'d' =>'xy', 'p' =>10}]]
    end
  end

  context "transform_cursor" do
    it "is sane" do
      described_class.transform_cursor(0, [], 'right').should == 0
      described_class.transform_cursor(0, [], 'left').should == 0
      described_class.transform_cursor(100, []).should == 100
    end

    it "works vs insert" do
      described_class.transform_cursor(0, [{'i' =>'asdf', 'p' =>100}], 'right').should == 0
      described_class.transform_cursor(0, [{'i' =>'asdf', 'p' =>100}], 'left').should == 0
      described_class.transform_cursor(200, [{'i' =>'asdf', 'p' =>100}], 'right').should == 204
      described_class.transform_cursor(200, [{'i' =>'asdf', 'p' =>100}], 'left').should == 204
      described_class.transform_cursor(100, [{'i' =>'asdf', 'p' =>100}], 'right').should == 104
      described_class.transform_cursor(100, [{'i' =>'asdf', 'p' =>100}], 'left').should == 100
    end

    it "works vs delete" do
      described_class.transform_cursor(0, [{'d' =>'asdf', 'p' =>100}], 'right').should == 0
      described_class.transform_cursor(0, [{'d' =>'asdf', 'p' =>100}], 'left').should == 0
      described_class.transform_cursor(0, [{'d' =>'asdf', 'p' =>100}]).should == 0
      described_class.transform_cursor(200, [{'d' =>'asdf', 'p' =>100}]).should == 196
      described_class.transform_cursor(100, [{'d' =>'asdf', 'p' =>100}]).should == 100
      described_class.transform_cursor(102, [{'d' =>'asdf', 'p' =>100}]).should == 100
      described_class.transform_cursor(104, [{'d' =>'asdf', 'p' =>100}]).should == 100
      described_class.transform_cursor(105, [{'d' =>'asdf', 'p' =>100}]).should == 101
    end
  end

  context "normalizer" do
    it "is sane" do
      described_class.normalize([]).should == []
      described_class.normalize([{'i' =>'asdf', 'p' =>100}]).should == [{'i' =>'asdf', 'p' =>100}]
      described_class.normalize([{'i' =>'asdf', 'p' =>100}, {'d' =>'fdsa', 'p' =>123}]).should == [{'i' =>'asdf', 'p' =>100}, {'d' =>'fdsa', 'p' =>123}]        
    end

    it "adds missing 'p' =>0" do
      described_class.normalize([{'i' =>'abc'}]).should == [{'i' =>'abc', 'p' =>0}]
      described_class.normalize([{'d' =>'abc'}]).should == [{'d' =>'abc', 'p' =>0}]
      described_class.normalize([{'i' =>'abc'}, {'d' =>'abc'}]).should == [{'i' =>'abc', 'p' =>0}, {'d' =>'abc', 'p' =>0}]
    end

    it "converts an op into an Array" do
      described_class.normalize({'i' =>'abc', 'p' =>0}).should == [{'i' =>'abc', 'p' =>0}]
      described_class.normalize({'d' =>'abc', 'p' =>0}).should == [{'d' =>'abc', 'p' =>0}]
    end

    it "converts a really simple op" do
      described_class.normalize({'i' =>'abc'}).should == [{'i' =>'abc', 'p' =>0}]
    end
  end
end


