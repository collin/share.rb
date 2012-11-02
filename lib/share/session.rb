require 'securerandom'

module Share
  class Session
    attr_reader :id

    def initialize(data, repo)
      @id = SecureRandom.hex
      @connect_time = Time.now()
      @headers = data[:headers]
      @remote_address = data[:remote_address]
      @repo = repo

      @listeners = {}
      @name = nil
    end

    def logger
      Rails.logger
    end

    def create(document_id, type, meta)
      type = TYPE_MAP[type] if type.is_a?(String)
      meta = {}
      meta[:creator] = @name if @name
      meta[:ctime] = meta[:mtime] = Time.now()
      meta[:v] = 0
      action = Action.new({name: document_id, type: type, meta: meta}, 'create')
      authorize! action
      meta[:snapshot] = type::DEFAULT_VALUE.dup
      @repo.create(document_id, meta, type)
    end

    def submit_op(document_id, operation)
      logger.debug "setup submit_op, #{operation}"
      operation[:meta] ||= {}
      operation[:meta][:source] = id
      dup_if_source = operation[:dup_if_source] || []
      if operation["op"]
        logger.debug "is operation"
        # action = Action.new({
        #   name: document.name, 
        #   type: document.type, 
        #   meta: operation[:meta], 
        #   v: operation["v"]},
        #   'submit op'
        # )
        # authorize! action
        @repo.apply_operation(document_id, operation[:v], operation[:op], operation[:meta], dup_if_source)
      else
        logger.debug "is meta operation"
        action = Action.new(
          {name: name, meta: operation[:meta]}, 'submit meta'
        )
        authorize! action
        @repo.apply_meta_operation!(name, operation)
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