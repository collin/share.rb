module Share
  class Action
    CONNECT = ['connect'].freeze!
    CREATE = ['create'].freeze!
    READ = ['get snapshot', 'get ops', 'open'].freeze!
    UPDATE = ['submit op', 'submit meta'].freeze!
    DELETE = ['delete'].freeze!

    ACTIONS = [
      CONNECT, CREATE, READ, UPDATE, DELETE
    ].freeze!

    def initialize(data, name)
      @data = data
      @name = name
      @type = ACTIONS.find { |action| action.include?(name) }
    end
  end
end