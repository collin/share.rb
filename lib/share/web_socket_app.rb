require "rack/websocket"
module Share
  class WebSocketApp < Rack::WebSocket::Application

    def initialize(repo, session)
      @repo = repo
      @session = session
      @protocol = Protocol.new(self, repo, session)
      super({})
    end

    def subscribe_to(document, at_version)
      @repo.subscribe @session.id, document, at_version, &method(:subscription_handler)
    end

    def unsubscribe_from(document)
      @repo.unsubscribe @session.id, document, &method(:subscription_handler)
    end

    # Rack::WebSocket callback
    def on_open(env)
      send_data protocol.handshake(session)
    end

    # Rack::WebSocket callback
    def on_close(env)

    end

    # Rack::WebSocket callback
    def on_error(env, error)

    end

    # Rack::WebSocket callback
    def on_message(env, raw_message)
      message = Message.new(raw_message)
      response = @protocol.respond_to(message)
      send_data response
    end

    def subscription_handler(operation)
      send_data @protocol.message_for_operation(operation)
    end

    def send_data(message)
      super JSON.encode(message)
    end
  end
end