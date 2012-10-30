module Share
  module Types
    LEFT = "left"
    RIGHT = "right"

    require_relative "./types/transform"
    require_relative "./types/json"
    require_relative "./types/text"

    TYPE_MAP = {
      'json' => Types::JSON,
      'text' => Types::Text
    }

    def self.[] name
      TYPE_MAP[name]
    end
  end
end