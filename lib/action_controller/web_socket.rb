module ActionController
  module WebSocket
    extend ActiveSupport::Concern
    
    def websocket_upgrade(websocket_app)
      upgrade_response = socket_application.new.call(request.env)
      self.status, self.headers, self.response_body = upgrade_response
    end
  end
end