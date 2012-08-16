module Share
  module Repo
    class InProcess < Abstract
  
      def create(id, meta)
        @adapter.new(id).create(id, meta)
      end

      def get_snapshot(id)
        @adapter.new(id).get_snapshot      
      end

      def subscribe(id, at_version, &block)
        document = @adapter.new(id)
        if at_version and document.operations_after_version(at_version).any?
          document.operations_after_version(at_version).each do |operation|
            block.call(operation)
          end
        end
        (@subscriptions[id] ||= []) << block
      end

      def unsubscribe(id, &block)
        @subscriptions[id] -= [block]
      end

      def apply_operation(id, version, operation, meta={}, dup_if_source=[])
        document = @adapter.new(id)
        document.write_op(
          op: operation,
          v: version,
          meta: meta
        )
      end
  
    end
  end
end