module ActionController
  module Share
    extend ActiveSupport::Concern

    include ActionController::WebSocket

    def share_repository(repository)
      logger.debug "Initializing Share::Session"
      session = ::Share::Session.new(connection_data, repository)
      logger.debug "Bulding Share::WebSocketApp"
      socket_application = ::Share::WebSocketApp.new(repository, session)
      logger.debug "Upgrading to WebSocket"
      websocket_upgrade socket_application
    end

    def connection_data
      return {
        headers: request.headers,
        remote_address: request.remote_addr
      }
    end
  end
end
