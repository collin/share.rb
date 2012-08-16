module Share
  module Adapter
    module Abstract
      class Document
        def initialize(name)
          @name = name
        end

        def create(data)
          raise "Undefined"
        end

        def delete(meta)
          raise "Undefined"
        end

        def get_snapshot
          raise "Undefined"
        end

        def write_snapshot(data, meta)
          raise "Undefined"
        end

        def get_ops(start_at, end_at=MAX_VERSION)
          raise "Undefined"
        end

        def write_op(data)
          raise "Undefined"
        end
        
      end
    end
  end
end