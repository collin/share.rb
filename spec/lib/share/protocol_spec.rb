require 'spec_helper'

class TestAdapter < Share::Adapter::Abstract::Document
  def self.create!(name, type, meta)
    new \
      doc: name,
      type: type,
      meta: meta
  end

  def exists?
    false
  end

  def meta
    :metadata
  end

  def type
    Share::Types['json']
  end

  def get_snapshot
    :snapshot
  end

  def version
    :version
  end

  def create(*)
    Object.new.tap do |o|
      class << o
        def meta; :metadata; end
        def type; Share::Types['json']; end
      end
    end
  end

  def last_op
    @last_op  ||= begin
      Object.new.tap do |o|
        class << o
          def v; :version; end
        end
      end
    end
  end

  def most_recent_snapshot
    Object.new.tap do |o|
      class << o
        def v; :version; end
        def snapshot; :snapshot; end
      end
    end
  end
end

class ExistingAdapter < TestAdapter
  def exists?
    true
  end

end

class TestWebSocketApp
  attr_reader :subscriptions
  def initialize(repo, session)
    @repo = repo
    @session = session
    @subscriptions = {}
  end

  def subscribe_to(document, at_version)
    @subscriptions[document] ||= []
    @subscriptions[document] << @session.id
  end

  def unsubscribe_from(document)
    @subscriptions[document] and @subscriptions[document] -= [@session.id]
  end
end

describe Share::Protocol do
  let(:app) do
    TestWebSocketApp.new(repo, session)
  end
  let(:adapter) { TestAdapter }
  let(:repo) { Share::Repo::InProcess.new(adapter: adapter) }
  let(:session) { Share::Session.new({}, repo) }
  let(:protocol) { Share::Protocol.new(app, repo, session) }
  let(:message) do
    require 'json'
    Share::Message.new ::JSON.dump(message_data)
  end

  it "creates a handshake response" do
    protocol.handshake.should == {auth: session.id}
  end
  
  describe "respond_to(message)" do
    let(:response) { protocol.respond_to message }

    describe "close message" do
      let(:message_data) do
        { doc: "test", open: false}
      end

      it "closes" do
        response[:open].should == false
      end
    end

    describe "creating a document that already exists" do
      let(:adapter) { ExistingAdapter }
      let(:message_data) do
        { doc: "test", create: true, type: "json" }
      end

      it "responds with create: false" do
        response[:create].should == false
      end
    end

    describe "creating a new document" do
      let(:message_data) do
        { doc: "test", create: true, type: "json" }
      end

      it "responds with create: true" do
        response[:create].should == true
      end

      it "responds with document metadata" do
        response[:meta].should == :metadata
      end
    end

    describe "document that doesn't exist" do
      let(:message_data) do
        { doc: "test", type: "json" }
      end

      it "responds with an error" do
        response.has_key?(:error).should == true
        response[:error].should match "Document does not exist"
      end
    end

    describe "document type doesn't match type in repo" do
      let(:message_data) do
        { doc: "test", type: "text"}
      end

      it "responds with an error" do
        response.has_key?(:error).should == true
        response[:error].should match "Type mismatch"
      end
    end

    describe "open request with an error" do
      let(:message_data) do
        { doc: "test", type: "text", open: true}
      end

      it "cancels opening the document" do
        response[:open].should == false
      end
    end

    describe "snapshot request" do
      let(:adapter) { ExistingAdapter }
      let(:message_data) do
        { doc: "test", type: "json", snapshot: nil}
      end

      it "responds with the snapshot" do
        response[:snapshot].should == :snapshot
      end
    end

    describe "open request" do
      let(:adapter) { ExistingAdapter }
      let(:message_data) do
        { doc: "test", open: true}
      end

      it "responds in the affirmative" do
        response[:open].should == true
      end

      it "responds with the opened version" do
        response[:v].should == :version
      end

      it "subscribes to the document" do
        response
        app.subscriptions["test"].include?(session.id).should == true
      end
    end
  end
end
