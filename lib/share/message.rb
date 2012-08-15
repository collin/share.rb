module Share
  class Message
    def initialize(raw_data)
      @data = JSON.parse raw_data
      validate!
    end

    def validate!
      if operation? || close? && ( create? || snapshot? || open? )
        raise ProtocolError.new("Bad combination of message properties.")
      end

      if create? && !type
        raise ProtocolError.new("Bad or missing type when creating document.")
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
      @data[:snapshot] == nil
    end

    def open?
      @data[:open] == true
    end

    def close?
      @data[:open] == false
    end

    def operation?
      @data[:operation]
    end

    def version
      @data[:version]
    end
  end
end