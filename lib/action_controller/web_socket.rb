module ActionController
  module WebSocket
    extend ActiveSupport::Concern
    
    def websocket_upgrade(socket_application)
      upgrade_response = socket_application.call(request.env)
      self.status, self.headers, self.response_body = upgrade_response
    end
  end
end