module Share
  class ProtocolError < ArgumentError; end

  class Protocol
    def initialize(app, repo, session)
      @app = app
      @repo = repo
      @session = session
      @current_document = nil
    end

    def logger
      Rails.logger
    end

    def respond_to(message)
      if message.auth?
        logger.warn "Unexpected auth message"
        return
      end
      logger.info "Protocol respond_to #{message}"
      # This got yucky fast.
      message.document and @current_document = message.document

      response = {doc: @current_document}

      document = @repo.get(@current_document)

      if message.create? && document.exists?
        logger.debug "requested create, but it exists"
        response[:create] = false
      elsif message.create?
        logger.debug "requested create"
        document = @session.create(@current_document, message.type, {})
        response[:create] = true
        response[:meta] = document.meta
      elsif !document.exists?
        logger.debug "document does not exist"
        response[:error] = "Document does not exist"
      end

      if message.operation?
        logger.debug(["operation", message].inspect)
        @session.submit_op(@current_document, message.data)
        return {v: message.data[:v]}
      end

      if document.type && message.type && document.type != message.type
        response[:error] = "Type mismatch"
      end

      if message.open? and response[:error]
        response[:open] = false
        return response
      end


      if message.open?
        logger.debug "opening document #{document}"
        @app.subscribe_to(@current_document, message.version)
        response[:open] = true
        response[:v] = document.version
      end

      if message.snapshot?
        logger.debug "Setting response snapshot #{document.snapshot}"
        response[:snapshot] = document.snapshot
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
        v: operation[:v],
        op: operation[:op],
        meta: operation[:meta]
      }
    end

    def handshake
      {auth: @session.id}
    end
  end
end