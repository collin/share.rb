# # require "action_controller/io_engine"

module ActionController
  module Share
    def share_with(backend)
      case backend
      when :websocket
        require "action_controller/web_socket"
        require "share/web_socket_app"
        include ::ActionController::WebSocket
        include ::ActionController::WebSocketShare
      else
        raise "ActionController::Share doesnt't have a backend #{backend}"
      end
    end
  end

  module WebSocketShare
    def share_repository(repository)
      session = ::Share::Session.new(connection_data, repository)
      application = ::Share::WebSocketApp.new(repository, session)
      websocket_upgrade application
    end

    def connection_data
      return {
        headers: request.headers,
        remote_address: request.remote_addr
      }
    end
  end
end
