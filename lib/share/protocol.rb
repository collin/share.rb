module Share
  class ProtocolError < ArgumentError; end

  class Protocol
    def initialize(app, repo, session)
      @app = app
      @repo = repo
      @session = session
      @current_document = nil
    end

    def respond_to(message)
      # This got yucky fast.
      message.document and @current_document = message.document

      response = {doc: @current_document}

      document = @repo.adapter.new(@current_document)

      if message.create? && document.exists?
        response[:create] = false
      elsif message.create?
        document = @session.create(@repo.adapter, @current_document, message.type, {})
        response[:create] = true
        response[:meta] = document.meta
      elsif !document.exists?
        response[:error] = "Document does not exist"
      end

      if document.type && message.type && document.type != message.type
        response[:error] = "Type mismatch"
      end

      if message.open? and response[:error]
        response[:open] = false
        return response
      end

      if message.snapshot?
        response[:snapshot] = document.get_snapshot
      end

      if message.open?
        @app.subscribe_to(@current_document, message.version)
        response[:open] = true
        response[:v] = document.version
      end

      if message.close?
        @app.unsubscribe_from(@current_document)
        response = {doc: @current_document, open: false}
      end

      response
    end

    def message_for_operation(operation)
      {
        doc: @current_document,
        v: operation.v,
        op: operation.op,
        meta: operation.meta
      }
    end

    def handshake
      {auth: @session.id}
    end
  end
end