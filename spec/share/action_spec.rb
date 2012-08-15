require_relative "../spec_helper"

describe Share::Action do
  it "wraps connect events" do
    Share::Action.new(nil, 'connect').type.must_equal Share::Action::CONNECT
  end

  it "wraps create events" do
    Share::Action.new(nil, 'create').type.must_equal Share::Action::CREATE
  end

  it "wraps read events" do
    ['get snapshot', 'get ops', 'open'].each do |name|
      Share::Action.new(nil, name).type.must_equal Share::Action::READ
    end
  end

  it "wraps update events" do
    ['submit op', 'submit meta'].each do |name|
      Share::Action.new(nil, name).type.must_equal Share::Action::UPDATE
    end    
  end

  it "wraps delete events" do
    Share::Action.new(nil, 'delete').type.must_equal Share::Action::DELETE
  end
end