require_relative "../spec_helper"

describe Share::Message do
  
  it "disallows creating with an op" do
    message = JSON.dump op: true, create: true
    proc do
      Share::Message.new(message).inspect      
    end.must_raise Share::ProtocolError
  end

  it "disallows requesting a snapshot with an op" do
    message = JSON.dump op: true, snapshot: nil
    proc do
      Share::Message.new(message).inspect      
    end.must_raise Share::ProtocolError    
  end

  it "disallows opening with an op" do
    message = JSON.dump op: true, open: true
    proc do
      Share::Message.new(message).inspect      
    end.must_raise Share::ProtocolError    
  end

  it "disallows close with create" do
    message = JSON.dump open: false, create: true
    proc do
      Share::Message.new(message).inspect      
    end.must_raise Share::ProtocolError        
  end

  it "disallows close with snapshot request" do
    message = JSON.dump open: false, snapshot: nil
    proc do
      Share::Message.new(message).inspect      
    end.must_raise Share::ProtocolError        
  end

end
