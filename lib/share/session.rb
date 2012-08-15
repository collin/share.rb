module Share
  class Session
    def initialize(data)
      @id = SecureRandom.hex
      @connect_time = Time.now()
      @headers = data[:headers]
      @remote_address = data[:remote_address]

      @listeners = {}
      @name = nil
    end

    def create(name, type, meta)
      type = TYPE_MAP[type] if type.is_a?(String)
      meta = {}
      meta[:creator] = @name if @name
      meta[:ctime] = meta.mtime = Date.current()
      action = Action.new(name: name, type: type, meta: meta, 'create')
      authorize! action
      Document.create!(name, type, meta)
    end

    def submit_op(name, data)
      data[:meta] ||= {}
      data[:meta].source = id
      dup_if_source = data.dup_if_source || []
      if data[OPERATION]
        action = Action.new(
          name: name, type: type, meta: data[:meta], VERSION => data[VERSION],
          'submit op'
        )
        authorize! action
        Document.apply_operation!(name, data)
      else
        action = Action.new(
          name: name, meta: data[:meta], 'submit meta'
        )
        authorize! action
        Document.apply_meta_operation!(name, data)
      end
    end

    def delete(name)
      action = Action.new(name: name, 'delete')
      authorize! action
      Document.delete!(name)
    end
  end
end