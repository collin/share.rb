module Share
  module Repo
    class Abstract

      class MissingAdapterError < ArgumentError; end

      def initialize(options = {})
        unless options[:adapter] && options[:adapter] < Share::Adapter::Abstract::Document
          raise MissingAdapterError < ArgumentError
        end

        @adapter = options[:adapter]
        @subscriptions = {}  
      end

      def create(id, meta)
        raise "Unimplemented"
      end

      def get_snapshot(id)
        raise "Unimplemented"      
      end

      def subscribe(id)
        raise "Unimplemented"
      end

      def unsubscribe(id)
        raise "Unimplemented"
      end

      def apply_operation(id, version, operation, meta={}, dup_if_source=[])
        raise "Unimplemented"
      end
    end
  end
end