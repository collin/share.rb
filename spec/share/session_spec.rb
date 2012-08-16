require_relative "../spec_helper"

describe Share::Session do
  it "generates a secure random id" do
    Share::Session.new({}).id.class.must_equal String
    Share::Session.new({}).id.length.must_equal 32
  end
end