require "thread_safe"
require "thread"

$LOAD_PATH.push File.join __FILE__, ".."
module Share
  def self.logger
    @logger ||= begin 
      _logger = if defined?(Rails)
        Rails.logger.dup
      else
        require 'logger'
        Logger.new(STDOUT)
      end
      # _logger.level = Logger::INFO
      _logger
    end
  end

  require "share/action"
  require "share/session"
  require "share/message"
  require "share/protocol"

  require "share/repo/abstract"
  require "share/repo/in_process"
  require "share/adapter/abstract"

  require "share/types"
end