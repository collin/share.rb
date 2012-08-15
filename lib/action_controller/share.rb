module ActionController
  module Share
    extend ActiveSupport::Concern

    include ActionController::WebSocket

    def share_repository(repository)
      session = ::Share::Session.new
      socket_application = ::Share::WebSocketApp.new(repository, session)
      websocket_upgrade socket_application
    end

  end
end


class LayoutsController < ApplicationController
  include ActionController::Share

  def index
    share_repository layouts_repository
  end

  def layouts_repository
    Thread.current[:layouts_repository] ||= begin
      Share::Repo::InProcess.new(
        adapter: Share::Adapter::ActiveRecord
      )
    end
  end
end
