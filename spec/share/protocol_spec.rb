require_relative "../spec_helper"

describe Share::Protocol do
  let(:session) { Share::Session.new({}) }
  let(:protocol) { Share::Protocol.new(nil, session) }

  it "creates a handshake response" do
    protocol.handshake.must_equal auth: session.id
  end

  describe "respond_to(message)" do
    let(:response) { protocol.respond_to message }

    describe "close message" do
      let(:message) do
        Share::Message.new JSON.dump(doc: "test", open: false)
      end

      it "closes" do
        assert response[:open] == false
      end
    end
  end
end
