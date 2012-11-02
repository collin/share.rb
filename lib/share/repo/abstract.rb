module Share
  module Repo
    class Abstract

      attr_reader :adapter

      class MissingAdapterError < ArgumentError; end

      def logger; Rails.logger end

      def initialize(options = {})
        logger.debug "Initializing #{self}"
        unless options[:adapter] && options[:adapter] < Share::Adapter::Abstract::Document
          raise MissingAdapterError.new
        end

        @adapter = options[:adapter]
        @documents = ThreadSafe::Hash.new
        logger.debug "Initialized #{self}"
      end

      def get(document_id)
        document = @documents[document_id] ||= begin
          @adapter.new(document_id)
        end
        document.cancel_reap_timer
        logger.debug "Got document #{document}"
        document
      end

      def create(id, data, type)
        get(id).create(data, type)
      end

      def get_snapshot(id)
        get(id).get_snapshot      
      end

      def subscribe(id, at_version, listener)
        document = get(id)
        logger.debug "adding observer #{listener} to #{document}"
        document.add_observer listener, :on_operation
        logger.debug "added observer #{listener} to #{document}"
      end

      def unsubscribe(id, listener)
        document = get(id)
        document.delete_observer listener
        return if document.count_observers > 0
        document.reap_timer { reap document }
      end

      # This got ugly
      def apply_operation(id, version, operation, meta={}, dup_if_source=[])
        document = get(id)
        document.synchronize do
          logger.debug "got version #{document}"

          if document.version == version
            operations = []
          else
            operations = document.get_ops(document.version, version)

            unless document.version - version == operations.length
              # This should never happen. It indicates that we didn't get all the ops we
              # asked for. Its important that the submitted op is correctly transformed.
              logger.error "Could not get old ops in model for document #{id}"
              logger.error "Expected ops #{version} to #{document.version} and got #{operations.length} ops"
              raise 'Internal error'
            end
          end

          begin
            operations.each do |_operation|
              if _operation.meta[:source] && 
                  _operation.dup_if_source && 
                  _operation.dup_if_source.includes?(_operation.meta[:source])

                raise "Op alread submitted"
              end
              operation[:op] = document.type.transform operation[:op], _operation.op, 'left'
              operation[:v] += 1
            end
          rescue Exception => error
            logger.error error
            logger.error error.backtrace.join("\n")
          end

          begin
            logger.debug [document.type, "apply", document.snapshot, operation]
            logger.debug ["snapshot:", document.snapshot]
            logger.debug ["operation:", operation]
            snapshot = document.type.apply document.snapshot, operation
            logger.debug ["new snapshot:", snapshot]
          rescue Exception => error
            logger.error error            
            logger.error error.backtrace.join("\n")
          end

          unless version == document.version
            logger.error "Version mismatch detected in model. File a ticket - this is a bug."
            logger.error "Expecting #{version} == #{document.version}"
            raise 'Internal error'
          end

          document.write_op(
            op: operation,
            v: version + 1,
            meta: meta
          )

          document.version = version + 1
          document.snapshot = snapshot
          logger.debug "Set version #{document}"
          document.notify_observers( v:version, op:operation, meta:meta )
        end
      end

      def reap(id)
        documents.delete id
      end
    end
  end
end