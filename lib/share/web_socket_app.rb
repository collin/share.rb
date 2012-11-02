require "rack/websocket"
class WebSocketError < StandardError; end
module Share
  class WebSocketApp < Rack::WebSocket::Application

    def initialize(repo, session)
      # FIXME: move repo into session, or out of session,
      # one of the two!
      @repo = repo
      @session = session
      @protocol = Protocol.new(self, repo, @session)
      super({})
    end

    def dup; self end # sounds dangerous!

    def logger
      Rails.logger
    end

    def subscribe_to(document_id, at_version)
      logger.debug "Subscribing to #{document_id}"
      @repo.subscribe document_id, at_version, self
      logger.debug "Subscribed to #{document_id}"
    end

    def unsubscribe_from(document_id)
      logger.debug "Unsubscribing from #{document_id}"
      @repo.unsubscribe document_id
    end

    # Rack::WebSocket callback
    def on_open(env)
      handshake = @protocol.handshake
      logger.debug "sending handshake: #{handshake}"
      send_data handshake
    end

    # Rack::WebSocket callback
    def on_close(env)

    end

    # Rack::WebSocket callback
    def on_error(env, error)

    end

    # Rack::WebSocket callback
    def on_message(env, raw_message)
      logger.debug "#{self} got message #{raw_message} in #{Thread.current}"
      message = Message.new(raw_message)
      logger.debug "Parsed message #{message}"
      response = @protocol.respond_to(message)
      logger.debug "Protocol response #{response}"
      send_data response if response
      logger.debug "Responded"
    rescue StandardError => error
      logger.error error
      logger.error caller * "\n"      
    end

    # update via observable
    def on_operation(operation)
      logger.debug "#{self} on_operation in #{Thread.current}"
      return if operation[:meta] && operation[:meta]["source"] == @session.id
      send_data @protocol.message_for_operation(operation)        
    end

    def send_data(message)
      logger.debug "Sending Message: #{message}"
      super JSON.dump(message)
    end
  end
end