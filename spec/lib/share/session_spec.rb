require 'spec_helper'

describe Share::Session do
  it "generates a secure random id" do
    Share::Session.new({}).id.class.should == String
    Share::Session.new({}).id.length.should == 32
  end
end