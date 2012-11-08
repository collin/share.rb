require "thread_safe"
require "thread"

$LOAD_PATH.push File.join __FILE__, ".."
module Share
  def self.logger
    @logger ||= begin 
      logger = if defined?(Rails)
        Share.logger.dup
      else
        require 'logger'
        Logger.new(STDOUT)
      end
      logger.level = Logger::INFO
      logger
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