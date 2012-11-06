require 'spec_helper'

describe Share::Session do
  it "generates a secure random id" do
    Share::Session.new({}, nil).id.class.should == String
    Share::Session.new({}, nil).id.length.should == 32
  end
end