require "thread_safe"
require "thread"

$LOAD_PATH.push File.join __FILE__, ".."
module Share
  def self.logger
    if defined?(Rails)
      Rails.logger
    else
      require 'logger'
      Logger.new(STDOUT)
    end
  end

  require "share/action"
  require "share/session"
  require "share/message"
  require "share/protocol"
  require "share/web_socket_app"

  require "share/repo/abstract"
  require "share/repo/in_process"
  require "share/adapter/abstract"

  require "share/types"
end