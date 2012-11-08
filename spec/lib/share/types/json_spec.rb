require 'spec_helper'

describe Share::Types::JSON do
  JSON = Share::Types::JSON
  context "sanity" do
    it 'compose od,oi --> od+oi' do
      JSON.compose([{'p' => ['foo'],'od' => 1}],[{'p' => ['foo'],'oi' => 2}]).should == [{'p' => ['foo'], 'od' => 1, 'oi' => 2}]
      JSON.compose([{'p' => ['foo'],'od' => 1}],[{'p' => ['bar'],'oi' => 2}]).should == [{'p' => ['foo'], 'od' => 1},{'p' => ['bar'], 'oi' => 2}]
    end

    it 'returns sane values for transform' do
      check = proc do |left, right|
        JSON.transform(left, right, 'left').should == left
        JSON.transform(left, right, 'right').should == left
      end

      check.call([], [])
      check.call([{'p' => ['foo'], 'oi' => 1}], [])
      check.call([{'p' => ['foo'], 'oi' => 1}], [{'p' => ['bar'], 'oi' => 2}])
    end
  end

  context "number" do
    it "adds numbers" do
      JSON.apply(1, [{'p' => [], 'na' => 2}]).should == 3
      JSON.apply([1], [{'p' => [0], 'na' => 2}]).should == [3]
    end

    it "Compose two adds together with the same path compresses them" do
      JSON.compose([{'p' => ['a', 'b'], 'na' => 1}], [{'p' => ['a', 'b'], 'na' => 2}]).should == [{'p' => ['a', 'b'], 'na' => 3}]
      JSON.compose([{'p' => ['a'], 'na' => 1}], [{'p' => ['b'], 'na' => 2}]).should == [{'p' => ['a'], 'na' => 1}, {'p' => ['b'], 'na' => 2}]
    end

    it "make sure append doesn't overwrite values when it merges number add" do
      rightHas = 21
      leftHas = 3

      right = [{'p' => [],'od' => 0,'oi' => 15},{'p' => [],'na' => 4},{'p' => [],'na' => 1},{'p' => [],'na' => 1}]
      left = [{'p' => [],'na' => 4},{'p' => [],'na' => -1}]
      
      right_ = JSON.transform(right, left, 'left')
      left_ = JSON.transform(left, right, 'right')

      s_c = JSON.apply rightHas, left_
      c_s = JSON.apply leftHas, right_

      s_c.should == c_s
    end
  end

  # Strings should be handled internally by the text type. We'll just do some basic sanity checks here.
  context "string" do
    it 'applies' do
      JSON.apply('a', [{'p' => [1], 'si' => 'bc'}]).should == 'abc'
      JSON.apply('abc', [{'p' => [0], 'sd' => 'a'}]).should == 'bc'
      JSON.apply({'x' => 'a'}, [{'p' => ['x', 1], 'si' => 'bc'}]).should == {'x' => 'abc'}      
    end

    it 'splits deletes w/transform' do
      JSON.transform([{'p' => [0], 'sd' => 'ab'}], [{'p' => [1], 'si' => 'x'}], 'left').should ==  [{'p' => [0], 'sd' => 'a'}, {'p' => [1], 'sd' => 'b'}]
    end
    
    it 'deletes cancel each other out' do
      JSON.transform([{'p' => ['k', 5], 'sd' => 'a'}], [{'p' => ['k', 5], 'sd' => 'a'}], 'left').should == []
    end
  end


  context "list" do
    it 'applies inserts' do
      JSON.apply(['b', 'c'], [{'p' => [0], 'li' => 'a'}]).should == ['a', 'b', 'c']
      JSON.apply(['a', 'c'], [{'p' => [1], 'li' => 'b'}]).should == ['a', 'b', 'c']
      JSON.apply(['a', 'b'], [{'p' => [2], 'li' => 'c'}]).should == ['a', 'b', 'c']
    end

    it 'applies deletes' do
      JSON.apply(['a', 'b', 'c'], [{'p' => [0], 'ld' => 'a'}]).should == ['b', 'c']
      JSON.apply(['a', 'b', 'c'], [{'p' => [1], 'ld' => 'b'}]).should == ['a', 'c']
      JSON.apply(['a', 'b', 'c'], [{'p' => [2], 'ld' => 'c'}]).should == ['a', 'b']
    end

    it 'replaces arrays' do
      JSON.apply(['a', 'x', 'b'], [{'p' => [1], 'ld' => 'x', 'li' => 'y'}]).should == ['a', 'y', 'b']
    end

    it 'applies moves' do
      JSON.apply(['b', 'a', 'c'], [{'p' => [1], 'lm' => 0}]).should == ['a', 'b', 'c']
      JSON.apply(['b', 'a', 'c'], [{'p' => [0], 'lm' => 1}]).should == ['a', 'b', 'c']
    end

    it 'Paths are bumped when list elements are inserted or removed' do
      JSON.transform([{'p' => [1, 200], 'si' => 'hi'}], [{'p' => [0], 'li' => 'x'}], 'left').should == [{'p' => [2, 200], 'si' => 'hi'}]
      JSON.transform([{'p' => [0, 201], 'si' => 'hi'}], [{'p' => [0], 'li' => 'x'}], 'right').should == [{'p' => [1, 201], 'si' => 'hi'}]
      JSON.transform([{'p' => [0, 202], 'si' => 'hi'}], [{'p' => [1], 'li' => 'x'}], 'left').should == [{'p' => [0, 202], 'si' => 'hi'}]

      JSON.transform([{'p' => [1, 203], 'si' => 'hi'}], [{'p' => [0], 'ld' => 'x'}], 'left').should == [{'p' => [0, 203], 'si' => 'hi'}]
      JSON.transform([{'p' => [0, 204], 'si' => 'hi'}], [{'p' => [1], 'ld' => 'x'}], 'left').should == [{'p' => [0, 204], 'si' => 'hi'}]
      JSON.transform([{'p' => ['x',3], 'si' => 'hi'}], [{'p' => ['x',0,'x'], 'li' => 0}], 'left').should == [{'p' => ['x',3], 'si' =>  'hi'}]
      JSON.transform([{'p' => ['x',3,'x'], 'si' => 'hi'}], [{'p' => ['x',5], 'li' => 0}], 'left').should == [{'p' => ['x',3,'x'], 'si' =>  'hi'}]
      JSON.transform([{'p' => ['x',3,'x'], 'si' => 'hi'}], [{'p' => ['x',0], 'li' => 0}], 'left').should == [{'p' => ['x',4,'x'], 'si' =>  'hi'}]

      JSON.transform([{'p' => [0],'ld' => 2}], [{'p' => [0],'li' => 1}], 'left').should == [{'p' => [1],'ld' => 2}]
      JSON.transform([{'p' => [0],'ld' => 2}], [{'p' => [0],'li' => 1}], 'right').should == [{'p' => [1],'ld' => 2}]
    end

    it 'Ops on deleted elements become noops' do
      JSON.transform([{'p' => [1, 0], 'si' => 'hi'}], [{'p' => [1], 'ld' => 'x'}], 'left').should == []
      JSON.transform([{'p' => [0],'li' => 'x'}], [{'p' => [0],'ld' => 'y'}], 'left').should == [{'p' => [0],'li' => 'x'}]
      JSON.transform([{'p' => [0],'na' => -3}], [{'p' => [0],'ld' => 48}], 'left').should == []
    end

    it 'Ops on replaced elements become noops' do
      JSON.transform([{'p' => [1, 0], 'si' => 'hi'}], [{'p' => [1], 'ld' => 'x', 'li' => 'y'}], 'left').should == []
      JSON.transform([{'p' => [0], 'li' => 'hi'}], [{'p' => [0], 'ld' => 'x', 'li' => 'y'}], 'left').should == [{'p' => [0], 'li' => 'hi'}]
    end

    it 'Deleted data is changed to reflect edits' do
      JSON.transform([{'p' => [1], 'ld' => 'a'}], [{'p' => [1, 1], 'si' => 'bc'}], 'left').should == [{'p' => [1], 'ld' => 'abc'}]
    end

    it 'Inserting then deleting an element composes into a no-op' do
      JSON.compose([{'p' => [1], 'li' => 'abc'}], [{'p' => [1], 'ld' => 'abc'}]).should == []
      JSON.transform([{'p' => [0],'ld' =>nil,'li'=>"x"}], [{'p' => [0],'li' => "The"}], 'right').should == [{'p' => [1],'ld'=>nil,'li' => 'x'}]
    end

    it 'Composing doesn\'t change the original object' do
      a = [{'p' => [0],'ld' => 'abc', 'li' => nil}]
      JSON.compose(a, [{'p' => [0],'ld' => nil}]).should == [{'p' => [0],'ld' => 'abc'}]
      a.should == [{'p' => [0],'ld' => 'abc', 'li' => nil}]
    end

    it 'If two inserts are simultaneous, the left op will end up first' do
      JSON.transform([{'p' => [1], 'li' => 'a'}], [{'p' => [1], 'li' => 'b'}], 'left').should == [{'p' => [1], 'li' => 'a'}]
      JSON.transform([{'p' => [1], 'li' => 'b'}], [{'p' => [1], 'li' => 'a'}], 'right').should == [{'p' => [2], 'li' => 'b'}]
    end

    it 'An attempt to re-delete a list element becomes a no-op' do
      JSON.transform([{'p' => [1], 'ld' => 'x'}], [{'p' => [1], 'ld' => 'x'}], 'left').should == []
      JSON.transform([{'p' => [1], 'ld' => 'x'}], [{'p' => [1], 'ld' => 'x'}], 'right').should == []
    end


    it 'Ops on a moved element move with the element' do
      JSON.transform([{'p' => [4], 'ld' => 'x'}], [{'p' => [4], 'lm' => 10}], 'left').should == [{'p' => [10], 'ld' => 'x'}]
      JSON.transform([{'p' => [4, 1], 'si' => 'a'}], [{'p' => [4], 'lm' => 10}], 'left').should == [{'p' => [10, 1], 'si' => 'a'}]
      JSON.transform([{'p' => [4, 1], 'li' => 'a'}], [{'p' => [4], 'lm' => 10}], 'left').should == [{'p' => [10, 1], 'li' => 'a'}]
      JSON.transform([{'p' => [4, 1], 'ld' => 'b', 'li' => 'a'}], [{'p' => [4], 'lm' => 10}], 'left').should == [{'p' => [10, 1], 'ld' => 'b', 'li' => 'a'}]

      JSON.transform([{'p' => [0],'li' =>nil}], [{'p' => [0],'lm' => 1}], 'left').should == [{'p' => [0],'li' => nil}]
      # [_,_,_,_,5,6,7,_]
      # 'c' =>  [_,_,_,_,5,'x',6,7,_]   'p' => 5 'li' => 'x'
      # 's' =>  [_,6,_,_,_,5,7,_]       'p' => 5 'lm' => 1
      # 'correct' =>  [_,6,_,_,_,5,'x',7,_]
      JSON.transform([{'p' => [5],'li' => 'x'}], [{'p' => [5],'lm' => 1}], 'left').should == [{'p' => [6],'li' => 'x'}]
      # [_,_,_,_,5,6,7,_]
      # 'c' =>  [_,_,_,_,5,6,7,_]  'p' => 5 'ld' => 6
      # 's' =>  [_,6,_,_,_,5,7,_]  'p' => 5 'lm' => 1
      # 'correct' =>  [_,_,_,_,5,7,_]
      JSON.transform([{'p' => [5],'ld' => 6}], [{'p' => [5],'lm' => 1}], 'left').should == [{'p' => [1],'ld' => 6}]
      #[{'p' => [0],'li' => {}}], JSON.transform [{'p' => [0],'li' => {}}], [{'p' => [0],'lm' => 0}], 'right'
      JSON.transform([{'p' => [0],'li' => []}], [{'p' => [1],'lm' => 0}], 'left').should == [{'p' => [0],'li' => []}]
      JSON.transform([{'p' => [2],'li' => 'x'}], [{'p' => [0],'lm' => 1}], 'left').should == [{'p' => [2],'li' => 'x'}]
    end

    it 'Target index of a moved element is changed by ld/li' do
      JSON.transform([{'p' => [0], 'lm' =>  2}], [{'p' => [1], 'ld' => 'x'}], 'left').should == [{'p' => [0],'lm' => 1}]
      JSON.transform([{'p' => [2], 'lm' =>  4}], [{'p' => [1], 'ld' => 'x'}], 'left').should == [{'p' => [1],'lm' => 3}]
      JSON.transform([{'p' => [0], 'lm' =>  2}], [{'p' => [1], 'li' => 'x'}], 'left').should == [{'p' => [0],'lm' => 3}]
      JSON.transform([{'p' => [2], 'lm' =>  4}], [{'p' => [1], 'li' => 'x'}], 'left').should == [{'p' => [3],'lm' => 5}]
      JSON.transform([{'p' => [0], 'lm' =>  0}], [{'p' => [0], 'li' => 28}], 'left').should == [{'p' => [1],'lm' => 1}]
    end

    it 'Tiebreak lm vs. ld/li' do
      JSON.transform([{'p' => [0], 'lm' =>  2}], [{'p' => [0], 'ld' => 'x'}], 'left').should == []
      JSON.transform([{'p' => [0], 'lm' =>  2}], [{'p' => [0], 'ld' => 'x'}], 'right').should == []
      JSON.transform([{'p' => [0], 'lm' =>  2}], [{'p' => [0], 'li' => 'x'}], 'left').should == [{'p' => [1], 'lm' => 3}]
      JSON.transform([{'p' => [0], 'lm' =>  2}], [{'p' => [0], 'li' => 'x'}], 'right').should == [{'p' => [1], 'lm' => 3}]
    end

    it 'replacement vs. deletion' do
      JSON.transform([{'p' => [0],'ld' => 'x','li' => 'y'}], [{'p' => [0],'ld' => 'x'}], 'right').should == [{'p' => [0],'li' => 'y'}]
    end

    it 'replacement vs. insertion' do
      JSON.transform([{'p' => [0],'ld' =>{},'li' => "brillig"}], [{'p' => [0],'li' => 36}], 'left').should == [{'p' => [1],'ld' => {},'li' => "brillig"}]
    end

    it 'replacement vs. replacement' do
      JSON.transform([{'p' => [0],'ld' => nil,'li' => []}], [{'p' => [0],'ld' => nil,'li' => 0}], 'right').should == []
      JSON.transform([{'p' => [0],'ld' => nil,'li' => 0}], [{'p' => [0],'ld' => nil,'li' => []}], 'left').should == [{'p' => [0],'ld' => [],'li' => 0}]
    end

    it 'composing replace with delete of replaced element results in insert' do
      JSON.compose([{'p' => [2],'ld' => [],'li'=>nil}], [{'p' => [2],'ld' => nil}]).should == [{'p' => [2],'ld' => []}]
    end

    it 'list move vs list move' do
      JSON.transform([{'p' => [0],'lm' => 2}], [{'p' => [2],'lm' => 1}], 'left').should == [{'p' => [0],'lm' => 2}]
      JSON.transform([{'p' => [3],'lm' => 3}], [{'p' => [5],'lm' => 0}], 'left').should == [{'p' => [4],'lm' => 4}]
      JSON.transform([{'p' => [2],'lm' => 0}], [{'p' => [1],'lm' => 0}], 'left').should == [{'p' => [2],'lm' => 0}]
      JSON.transform([{'p' => [2],'lm' => 0}], [{'p' => [1],'lm' => 0}], 'right').should == [{'p' => [2],'lm' => 1}]
      JSON.transform([{'p' => [2],'lm' => 0}], [{'p' => [5],'lm' => 0}], 'right').should == [{'p' => [3],'lm' => 1}]
      JSON.transform([{'p' => [2],'lm' => 0}], [{'p' => [5],'lm' => 0}], 'left').should == [{'p' => [3],'lm' => 0}]
      JSON.transform([{'p' => [2],'lm' => 5}], [{'p' => [2],'lm' => 0}], 'left').should == [{'p' => [0],'lm' => 5}]
      JSON.transform([{'p' => [2],'lm' => 5}], [{'p' => [2],'lm' => 0}], 'left').should == [{'p' => [0],'lm' => 5}]
      JSON.transform([{'p' => [1],'lm' => 0}], [{'p' => [0],'lm' => 5}], 'right').should == [{'p' => [0],'lm' => 0}]
      JSON.transform([{'p' => [1],'lm' => 0}], [{'p' => [0],'lm' => 1}], 'right').should == [{'p' => [0],'lm' => 0}]
      JSON.transform([{'p' => [0],'lm' => 1}], [{'p' => [1],'lm' => 0}], 'left').should == [{'p' => [1],'lm' => 1}]
      JSON.transform([{'p' => [0],'lm' => 1}], [{'p' => [5],'lm' => 0}], 'right').should == [{'p' => [1],'lm' => 2}]
      JSON.transform([{'p' => [2],'lm' => 1}], [{'p' => [5],'lm' => 0}], 'right').should == [{'p' => [3],'lm' => 2}]
      JSON.transform([{'p' => [3],'lm' => 1}], [{'p' => [1],'lm' => 3}], 'left').should == [{'p' => [2],'lm' => 1}]
      JSON.transform([{'p' => [1],'lm' => 3}], [{'p' => [3],'lm' => 1}], 'left').should == [{'p' => [2],'lm' => 3}]
      JSON.transform([{'p' => [2],'lm' => 6}], [{'p' => [0],'lm' => 1}], 'left').should == [{'p' => [2],'lm' => 6}]
      JSON.transform([{'p' => [2],'lm' => 6}], [{'p' => [0],'lm' => 1}], 'right').should == [{'p' => [2],'lm' => 6}]
      JSON.transform([{'p' => [2],'lm' => 6}], [{'p' => [1],'lm' => 0}], 'left').should == [{'p' => [2],'lm' => 6}]
      JSON.transform([{'p' => [2],'lm' => 6}], [{'p' => [1],'lm' => 0}], 'right').should == [{'p' => [2],'lm' => 6}]
      JSON.transform([{'p' => [0],'lm' => 1}], [{'p' => [2],'lm' => 1}], 'left').should == [{'p' => [0],'lm' => 2}]
      JSON.transform([{'p' => [2],'lm' => 1}], [{'p' => [0],'lm' => 1}], 'right').should == [{'p' => [2],'lm' => 0}]
      JSON.transform([{'p' => [0],'lm' => 0}], [{'p' => [1],'lm' => 0}], 'left').should == [{'p' => [1],'lm' => 1}]
      JSON.transform([{'p' => [0],'lm' => 1}], [{'p' => [1],'lm' => 3}], 'left').should == [{'p' => [0],'lm' => 0}]
      JSON.transform([{'p' => [2],'lm' => 1}], [{'p' => [3],'lm' => 2}], 'left').should == [{'p' => [3],'lm' => 1}]
      JSON.transform([{'p' => [3],'lm' => 2}], [{'p' => [2],'lm' => 1}], 'left').should == [{'p' => [3],'lm' => 3}]
    end

    it 'indices change correctly around a move' do
      JSON.transform([{'p' => [0,0],'li' => {}}], [{'p' => [1],'lm' => 0}], 'left').should == [{'p' => [1,0],'li' => {}}]
      JSON.transform([{'p' => [1],'lm' => 0}], [{'p' => [0],'ld' => {}}], 'left').should == [{'p' => [0],'lm' => 0}]
      JSON.transform([{'p' => [0],'lm' => 1}], [{'p' => [1],'ld' => {}}], 'left').should == [{'p' => [0],'lm' => 0}]
      JSON.transform([{'p' => [6],'lm' => 0}], [{'p' => [2],'ld' => {}}], 'left').should == [{'p' => [5],'lm' => 0}]
      JSON.transform([{'p' => [1],'lm' => 0}], [{'p' => [2],'ld' => {}}], 'left').should == [{'p' => [1],'lm' => 0}]
      JSON.transform([{'p' => [2],'lm' => 1}], [{'p' => [1],'ld' => 3}], 'right').should == [{'p' => [1],'lm' => 1}]

      JSON.transform([{'p' => [2],'ld' => {}}], [{'p' => [1],'lm' => 2}], 'right').should == [{'p' => [1],'ld' => {}}]
      JSON.transform([{'p' => [1],'ld' => {}}], [{'p' => [2],'lm' => 1}], 'left').should == [{'p' => [2],'ld' => {}}]


      JSON.transform([{'p' => [1],'ld' => {}}], [{'p' => [0],'lm' => 1}], 'right').should == [{'p' => [0],'ld' => {}}]

      JSON.transform([{'p' => [1],'ld' => 1,'li' => 2}], [{'p' => [1],'lm' => 0}], 'left').should == [{'p' => [0],'ld' => 1,'li' => 2}]
      JSON.transform([{'p' => [1],'ld' => 2,'li' => 3}], [{'p' => [0],'lm' => 1}], 'left').should == [{'p' => [0],'ld' => 2,'li' => 3}]
      JSON.transform([{'p' => [0],'ld' => 3,'li' => 4}], [{'p' => [1],'lm' => 0}], 'left').should == [{'p' => [1],'ld' => 3,'li' => 4}]
    end

    it 'li vs lm' do
      li = proc { |p|   [{'p' => [p],'li' => []}] }
      lm = proc { |f,t| [{'p' => [f],'lm' => t}]  }

      JSON.transform(li.call(0), lm.call(1, 3), 'left').should == li.call(0)
      JSON.transform(li.call(1), lm.call(1, 3), 'left').should == li.call(1)
      JSON.transform(li.call(2), lm.call(1, 3), 'left').should == li.call(1)
      JSON.transform(li.call(3), lm.call(1, 3), 'left').should == li.call(2)
      JSON.transform(li.call(4), lm.call(1, 3), 'left').should == li.call(4)

      JSON.transform(lm.call(1, 3), li.call(0), 'right').should == lm.call(2, 4)
      JSON.transform(lm.call(1, 3), li.call(1), 'right').should == lm.call(2, 4)
      JSON.transform(lm.call(1, 3), li.call(2), 'right').should == lm.call(1, 4)
      JSON.transform(lm.call(1, 3), li.call(3), 'right').should == lm.call(1, 4)
      JSON.transform(lm.call(1, 3), li.call(4), 'right').should == lm.call(1, 3)

      JSON.transform(li.call(0), lm.call(1, 2), 'left').should == li.call(0)
      JSON.transform(li.call(1), lm.call(1, 2), 'left').should == li.call(1)
      JSON.transform(li.call(2), lm.call(1, 2), 'left').should == li.call(1)
      JSON.transform(li.call(3), lm.call(1, 2), 'left').should == li.call(3)

      JSON.transform(li.call(0), lm.call(3, 1), 'left').should == li.call(0)
      JSON.transform(li.call(1), lm.call(3, 1), 'left').should == li.call(1)
      JSON.transform(li.call(2), lm.call(3, 1), 'left').should == li.call(3)
      JSON.transform(li.call(3), lm.call(3, 1), 'left').should == li.call(4)
      JSON.transform(li.call(4), lm.call(3, 1), 'left').should == li.call(4)

      JSON.transform(lm.call(3, 1), li.call(0), 'right').should == lm.call(4, 2)
      JSON.transform(lm.call(3, 1), li.call(1), 'right').should == lm.call(4, 2)
      JSON.transform(lm.call(3, 1), li.call(2), 'right').should == lm.call(4, 1)
      JSON.transform(lm.call(3, 1), li.call(3), 'right').should == lm.call(4, 1)
      JSON.transform(lm.call(3, 1), li.call(4), 'right').should == lm.call(3, 1)

      JSON.transform(li.call(0), lm.call(2, 1), 'left').should == li.call(0)
      JSON.transform(li.call(1), lm.call(2, 1), 'left').should == li.call(1)
      JSON.transform(li.call(2), lm.call(2, 1), 'left').should == li.call(3)
      JSON.transform(li.call(3), lm.call(2, 1), 'left').should == li.call(3)
    end
  end

  context "object" do
    it 'Apply sanity checks' do
      JSON.apply({'x' => 'a'}, [{'p' => ['y'], 'oi' => 'b'}]).should == {'x' => 'a', 'y' => 'b'}
      JSON.apply({'x' => 'a'}, [{'p' => ['x'], 'od' => 'a'}]).should == {}
      JSON.apply({'x' => 'a'}, [{'p' => ['x'], 'od' => 'a', 'oi' => 'b'}]).should == {'x' => 'b'}
    end

    it 'Ops on deleted elements become noops' do
      JSON.transform([{'p' => [1, 0], 'si' => 'hi'}], [{'p' => [1], 'od' => 'x'}], 'left').should == []
      JSON.transform([{'p' => [9],'si' => "bite "}], [{'p' => [],'od' => "agimble s",'oi'=>nil}], 'right').should == []
    end

    it 'Ops on replaced elements become noops' do
      JSON.transform([{'p' => [1, 0], 'si' => 'hi'}], [{'p' => [1], 'od' => 'x', 'oi' => 'y'}], 'left').should == []
    end

    it 'Deleted data is changed to reflect edits' do
      JSON.transform([{'p' => [1], 'od' => 'a'}], [{'p' => [1, 1], 'si' => 'bc'}], 'left').should == [{'p' => [1], 'od' => 'abc'}]
      JSON.transform([{'p' => [],'od' => 22,'oi' => []}], [{'p' => [],'na' => 3}], 'left').should == [{'p' => [],'od' => 25,'oi' => []}]
      JSON.transform([{'p' => [],'od' => {'toves' => 0},'oi' => 4}], [{'p' => ["toves"],'od' => 0,'oi' => ""}], 'left').should == [{'p' => [],'od' => {'toves' => ""},'oi' => 4}]
      JSON.transform([{'p' => [],'od' => "thou and ",'oi' => []}], [{'p' => [7],'sd' => "d "}], 'left').should == [{'p' => [],'od' => "thou an",'oi' => []}]
      JSON.transform([{'p' => ["bird"],'na' => 2}], [{'p' => [],'od' => {'bird' => 38},'oi' => 20}], 'right').should == []
      JSON.transform([{'p' => [],'od' => {'bird' => 38},'oi' => 20}], [{'p' => ["bird"],'na' => 2}], 'left').should == [{'p' => [],'od' => {'bird' => 40},'oi' => 20}]
      JSON.transform([{'p' => ["He"],'od' => []}], [{'p' => ["The"],'na' => -3}], 'right').should == [{'p' => ['He'],'od' => []}]
      JSON.transform([{'p' => ["He"],'oi' => {}}], [{'p' => [],'od' => {},'oi' => "the"}], 'left').should == []
    end

    it 'If two inserts are simultaneous, the lefts insert will win' do
      JSON.transform([{'p' => [1], 'oi' => 'a'}], [{'p' => [1], 'oi' => 'b'}], 'left').should == [{'p' => [1], 'oi' => 'a', 'od' => 'b'}]
      JSON.transform([{'p' => [1], 'oi' => 'b'}], [{'p' => [1], 'oi' => 'a'}], 'right').should == []
    end

    it 'parallel ops on different keys miss each other' do
      JSON.transform([{'p' => ['a'], 'oi' => 'x'}], [{'p' => ['b'], 'oi' => 'z'}], 'left').should == [{'p' => ['a'], 'oi' =>  'x'}]
      JSON.transform([{'p' => ['a'], 'oi' => 'x'}], [{'p' => ['b'], 'od' => 'z'}], 'left').should == [{'p' => ['a'], 'oi' =>  'x'}]
      JSON.transform([{'p' => ["in","he"],'oi' => {}}], [{'p' => ["and"],'od' => {}}], 'right').should == [{'p' => ["in","he"],'oi' => {}}]
      JSON.transform([{'p' => ['x',0],'si' => "his "}], [{'p' => ['y'],'od' => 0,'oi' => 1}], 'right').should == [{'p' => ['x',0],'si' => "his "}]
    end

    it 'replacement vs. deletion' do
      JSON.transform([{'p' => [],'od' => [''],'oi' => {}}], [{'p' => [],'od' => ['']}], 'right').should == [{'p' => [],'oi' => {}}]
    end

    it 'replacement vs. replacement' do
      JSON.transform([{'p' => [],'od' => ['']},{'p' => [],'oi' => {}}], [{'p' => [],'od' => ['']},{'p' => [],'oi' => nil}], 'right').should == []
      JSON.transform([{'p' => [],'od' => ['']},{'p' => [],'oi' => {}}], [{'p' => [],'od' => ['']},{'p' => [],'oi' => nil}], 'left').should == [{'p' => [],'od' => nil ,'oi' =>{}}]
      JSON.transform([{'p' => [],'od' => [''],'oi' => {}}], [{'p' => [],'od' => [''],'oi' => nil}], 'right').should == []
      JSON.transform([{'p' => [],'od' => [''],'oi' => {}}], [{'p' => [],'od' => [''],'oi' => nil}], 'left').should == [{'p' => [],'od' => nil,'oi' => {}}]
    
      # test diamond property
      rightOps = [ {"p" => [],"od" => nil,"oi" => {}} ]
      leftOps = [ {"p" => [],"od" => nil,"oi" => ""} ]

      rightHas = JSON.apply(nil, rightOps)
      leftHas = JSON.apply(nil, leftOps)

      left_ = JSON.transform(leftOps, rightOps, 'left')
      right_ = JSON.transform(rightOps, leftOps, 'right')

      JSON.apply(rightHas, left_).should == leftHas
      JSON.apply(leftHas, right_).should == leftHas
    end

    it 'An attempt to re-delete a key becomes a no-op' do
      JSON.transform([{'p' => ['k'], 'od' => 'x'}], [{'p' => ['k'], 'od' => 'x'}], 'left').should == []
      JSON.transform([{'p' => ['k'], 'od' => 'x'}], [{'p' => ['k'], 'od' => 'x'}], 'right').should == []
    end
  end
end