module Share
  module Adapter
    module ActiveRecord
      MAX_VERSION = 2147483647

      class CreateOperations < ::ActiveRecord::Migration
        def up
          create_table 'share:operations' do |t|
            t.text :doc, null: false
            t.integer :v, null: false
            t.text :op, null: false
            t.text :meta, null: false
          end

          add_index 'share:operations', [:doc, :v], unique: true
        end

        def down
          drop_table :operations
        end
      end

      class CreateSnapshots < ::ActiveRecord::Migration
        def up
          create_table 'share:snapshots' do |t|
            t.text :doc, null: false
            t.integer :v, null: false
            t.text :_type, null: false
            t.text :snapshot, null: false
            t.text :meta, null: false
            t.timestamps            
          end

          add_index 'share:snapshots', [:doc, :v], unique: true
        end

        def down
          drop_table :snapshots
        end
      end

      class Operation < ::ActiveRecord::Base
        self.table_name = 'share:operations'
        attr_accessible :doc, :v, :op, :meta

        serialize :op, JSON
        serialize :meta, JSON
      end

      module TypeLoader
        def self.dump(type)
          type.name
        end

        def self.load(value)
          value.constantize
        end
      end

      class Snapshot < ::ActiveRecord::Base
        self.table_name = 'share:snapshots'
        attr_accessible :doc, :v, :snapshot, :meta, :_type

        serialize :snapshot, JSON
        serialize :meta, JSON
        serialize :_type, TypeLoader
      end

      class Document < Abstract::Document
        def self.create_tables
          CreateOperations.migrate(:up) unless Operation.table_exists?
          CreateSnapshots.migrate(:up) unless Snapshot.table_exists?
        end

        def exists?
          @exists ||= Snapshot.where(doc: @name).any?
        end

        def create(data, type)
          Snapshot.create!(
            doc: @name,
            v: data[:v],
            snapshot: data[:snapshot],
            meta: data[:meta],
            _type: type
          )
          self
        end

        def name
          @name
        end

        def type
          get_snapshot._type if exists?
        end

        def meta
          get_snapshot.meta if exists?
        end

        def snapshot
          get_snapshot.snapshot if exists?
        end

        def delete(meta)
          [Operation.where(doc: @name).destroy_all,
          Snapshot.where(doc: @name).destroy_all]
        end

        def get_snapshot
          @snapshot ||= Snapshot.where(doc: @name).order('v DESC').first
        end

        def write_snapshot(data, meta)
          Snapshot.where(doc: @name).update_attributes(
            v: data[:v],
            snapshot: data[:snapshot],
            meta: data[:meta]
          )
        end

        def get_ops(start_at, end_at=MAX_VERSION)
          Operation.where(
            v: start_at..end_at,
            doc: @name
          )
        end

        def last_op
          get_ops(0).last
        end

        def write_op(data)
          Operation.create!(
            doc: @name,
            op: data[:op],
            v: data[:v],
            meta: data[:meta]
          )
        end
      end
    end
  end
end