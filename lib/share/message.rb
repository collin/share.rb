require 'json'
require 'active_support/hash_with_indifferent_access'


module Share
  class Message
    HWIA = ActiveSupport::HashWithIndifferentAccess

    attr_reader :data

    def initialize(raw_data)
      @data = HWIA.new JSON.parse(raw_data)
      validate!
    end

    def to_s
      "<#{self.class} #{@data} >"
    end

    alias inspect to_s

    def validate!
      if (operation? || close?) && ( create? || snapshot? || open? )
        raise ProtocolError.new \
          ["Bad combination of message properties.", @data.inspect]
      end

      if create? && !type
        raise ProtocolError.new \
          ["Bad or missing type when creating document.", @data.inspect]
      end
    end

    def document
      @data[:doc]
    end

    def type
      Share::Types[@data[:type]]
    end

    def create?
      @data[:create]
    end

    def snapshot?
      @data.key?(:snapshot) && @data[:snapshot] == nil
    end

    def open?
      @data[:open] == true
    end

    def close?
      @data[:open] == false
    end

    def auth?
      @data.has_key?(:auth)
    end

    def operation?
      operation
    end

    def operation
      @data[:op]
    end

    def version
      @data[:version]
    end
  end
end