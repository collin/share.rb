require "action_controller/share"
class DocumentsController < ApplicationController
  extend ActionController::Share
  share_with :websocket

  def show
    @document_id = params[:id]
  end

  def share
    share_repository documents_repository
  end

  def documents_repository
    Thread.current[:documents_repository] ||= begin
      Share::Repo::InProcess.new(
        adapter: Share::Adapter::ActiveRecord::Document
      )
    end
  end
end
