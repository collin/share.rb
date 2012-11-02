require "action_controller/share"
class PadsController < ApplicationController
  include ActionController::Share

  def show
    @pad_id = params[:id]
  end

  def share
    share_repository(pads_repository)
  end

  def pads_repository
    Thread.current[:pads_repository] ||= begin
      Share::Repo::InProcess.new(
        adapter: Share::Adapter::ActiveRecord::Document
      )
    end
  end
end
