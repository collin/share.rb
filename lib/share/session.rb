require 'securerandom'

module Share
  class Session
    attr_reader :id

    def initialize(data)
      @id = SecureRandom.hex
      @connect_time = Time.now()
      @headers = data[:headers]
      @remote_address = data[:remote_address]

      @listeners = {}
      @name = nil
    end

    def create(adapter, name, type, meta)
      type = TYPE_MAP[type] if type.is_a?(String)
      meta = {}
      meta[:creator] = @name if @name
      meta[:ctime] = meta[:mtime] = Time.now()
      action = Action.new({name: name, type: type, meta: meta}, 'create')
      authorize! action
      adapter.create!(name, type, meta)
    end

    def submit_op(adapter, name, data)
      data[:meta] ||= {}
      data[:meta].source = id
      dup_if_source = data.dup_if_source || []
      if data[OPERATION]
        action = Action.new(
          {name: name, type: type, meta: data[:meta], VERSION => data[VERSION]},
          'submit op'
        )
        authorize! action
        adapter.apply_operation!(name, data)
      else
        action = Action.new(
          {name: name, meta: data[:meta]}, 'submit meta'
        )
        authorize! action
        adapter.apply_meta_operation!(name, data)
      end
    end

    def authorize!(action)
      
    end

    def delete(adapter, name)
      action = Action.new({name: name}, 'delete')
      authorize! action
      adapter.delete!(name)
    end
  end
end