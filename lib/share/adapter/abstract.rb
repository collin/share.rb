require "thread"

module Share
  module Adapter
    module Abstract
      class Document
        REAP_TIME = 60 * 60 # 1.minute

        attr_accessor :version
        attr_accessor :snapshot
        attr_reader :name

        def initialize(name)
          @name = name
          @mutex = Mutex.new
          @observers = Hash.new
          @version = if operation = last_op
            operation.v
          else
            0
          end
        end

        def to_s
          "<#{self.class} #{@name} v:#{@version}>"
        end

        alias inspect to_s

        def add_observer(observer, message=:update)
          synchronize do
            @observers[observer] = message            
          end
        end

        def delete_observer(observer)
          synchronize do
            @observer.delete(observer)            
          end
        end

        def notify_observers(*payload)
          # synchronize do
            @observers.each do |observer, message|
              observer.send message, *payload
            end            
          # end
        end

        def synchronize(&block)
          @mutex.synchronize &block
        end

        def changed; end # no-op

        def create!(data)
          raise "Undefined"
        end

        def exists?
          raise "Undefined"
        end

        def type
          raise "Undefined"
        end

        def verison
          raise "Undefined"          
        end

        def meta
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
        
        def reap_timer(&block)
          cancel_reap_timer
          @timer = EventMachine::Timer.new REAP_TIME, &block
        end

        def cancel_reap_timer
          return unless @timer
          @timer.cancel
          @timer = nil
        end
      end
    end
  end
end