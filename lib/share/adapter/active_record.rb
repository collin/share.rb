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
          drop-table :operations
        end
      end

      class CreateSnapshots < ::ActiveRecord::Migration
        def up
          create_table 'share:snapshots' do |t|
            t.text :doc, null: false
            t.integer :v, null: false
            t.text :type, null: false
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

      class Operation < ActiveRecord::Base
        set_table_name 'share:operations'
        attr_accessible :doc, :v, :op, :meta

        serialize :op, JSON
        serialize :meta, JSON
      end

      class Snapshot < ActiveRecord::Base
        set_table_name 'share:snapshots'
        attr_accessible :doc, :v, :snapshot, :meta

        serialize :snapshot, JSON
        serialize :meta, JSON
      end

      class Document
        def self.create_tables
          CreateOperations.migrate(:up) unless Operation.table_exists?
          CreateSnapshots.migrate(:up) unless Snapshot.table_exists?
        end

        def initialize(name)
          @name = name
        end

        def create(data)
          Snapshot.create!
            doc: @name,
            v: data[:v],
            snapshot: docData[:snapshot],
            meta: docData[:meta],
            type: docData[:type]
        end

        def delete(meta)
          [Operations.where(doc: @name).destroy_all,
          Snapshot.where(doc: @name).destroy_all]
        end

        def get_snapshot
          Snapshot.where(doc: @name).order_by(:v).first
        end

        def write_snapshot(data, meta)
          Snapshot.where(doc: @name).update_attributes(
            v: data[:v],
            snapshot: data[:snapshot],
            meta: data[:meta]
          )
        end

        def get_ops(start_at, end_at=MAX_VERSION)
          Operations.where(
            v: [start_at, end_at]
            doc: @name
          )
        end

        def write_op(data)
          Operations.create!(
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