module Share
  module Types
    module Text
      INSERT = :i
      DELETE = :d
      POSITION = :p

      def inject(left, position, right)
        left[0, position] + right + left[position, left.length]
      end

      def create
        ''
      end

      def check_valid_component(component)
        raise MissingPositionField.new(component) unless component[POSITION].is_a?(Fixnum)
        insert_type = component[INSERT].class
        delete_type = component[DELETE].class

        raise MissingInsertOrDelete.new(component) unless component[INSERT] || component[DELETE]
        raise NegativePositionError.new(component) unless component[POSITION] >= 0
      end

      def check_valid_operation(operation)
        operation.each { |component| check_valid_component(component) }
        true
      end

      def apply(snapshot, operation)
        check_valid_operation operation
        operation.each do |component|
          if component[INSERT]
            snapshot = inject snapshot, component[POSITION], component[INSERT]
          else
            deleted = snapshot[component[POSITION], component[POSITION] + component[DELETE].length]
            unless component[DELETE] == deleted
              raise DeletedStringDoesNotMatch.new(component, deleted)
            end
            snapshot = snapshot[0, component[POSITION]] + snapshot[component[POSITION] + component[DELETE].length, snapshot.length]
          end
        end
      end

      def _append(new_operation, component)
        return if component[INSERT] == '' || component[DELETE] == ''
        if new_operation.length == 0
          new_operation.push component
        else
          last = new_operation.last
          if last[INSERT] && component[INSERT] && last[POSITION] <= component[PATH] && component[PATH] <= (last[POSITION] + last[INSERT].length)
            new_operation[new_operation.length - 1] = {
              INSERT => inject(last[INSERT], component[POSITION] - last[POSITION], component[INSERT]),
              POSITION => last[POSITION]
            }
          elsif last[DELETE] && component[DELETE] && component[POSITION] <= last[POSITION] && last[POSITION] <= (component[POSITION] + component[DELETE].length)
            new_operation[new_operation.length - 1] = {
              DELETE => inject(component[DELETE], last[POSITION] - component[POSITION], last[DELETE]),
              POSITION => component[POSITION]
            }
          else
            new_operation.push component
          end
        end
      end

      def compose(left, right)
        check_valid_operation left
        check_valid_operation right

        new_operation = left.dup
        right.each { |component| append new_operation, component }

        return new_operation
      end

      def compress(operation)
        compose [], operation
      end

      def normalize(operation)
        new_operation = []
        # Normalize should allow ops which are a single (unwrapped) component:
        # {i:'asdf', p:23}.
        # There's no good way to test if something is an array:
        # http://perfectionkills.com/instanceof-considered-harmful-or-how-to-write-a-robust-isarray/
        # so this is probably the least bad solution.
        operation = [operation] unless operation.is_a?(Array)

        operation.each do |component|
          component[POSITION] ||= 0
          append new_operation, component
        end

        new_operation
      end

      def transform_position(position, component, insert_after=false)
        if component[INSERT]
          if component[POSITION] < position || (component[POSITION] == position && insert_after)
            position + component[INSERT].length
          else
            position
          end
        else
          if position <= component[POSITION]
            position
          elsif position <= component[POSITION] + component[DELETE].length
            component[POSITION]
          else
            position - component[DELETE].length
          end
        end
      end

      def transform_cursor(position, operation, side)
        insert_after = side == RIGHT
        operation.each do |component|
          position = transform_position position, component, insert_after
        end
        position
      end

      def transform_component(destination, component, other, side)
        check_valid_operation [component]
        check_valid_operation [other]

        if component[INSERT]
          append destination, {
            INSERT => component[INSERT],
            POSITION => transform_position(component[POSITION], other, side == RIGHT)
          }
        elsif component[DELETE]
          if component[POSITION] >= other[POSITION] + other[DELETE].length
            append destination, {
              DELETE => component[DELETE],
              POSITION => component[POSITION] - other[DELETE].length
            }
          elsif component[POSITION] + component[DELETE].length <= other[POSITION]
            append destination, component
          else
            # They overlap somewhere.
            new_component = {DELETE => '', POSITION => component[POSITION]}
            if component[POSITION] < other[POSITION]
              new_component[DELETE] = component[DELETE][0, other[POSITION] - component[POSITION]
            end

            if component[POSITION] + component[DELETE].length > other[POSITION] + other[DELETE].length
              new_component[DELETE] += component[DELETE][other[POSITION] + other[DELETE].length, component[DELETE].length]
            end

            # This is entirely optional - just for a check that the deleted
            # text in the two ops matches
            intersect_start = [component[POSITION], other[POSITION]].max
            intersect_end = [component[POSITION] + component[DELETE].length, other[POSITION] + other[DELETE].length].min

            intersect = component[DELETE][intersect_start - component[POSITION], intersect_end - component[POSITION]]
            other_intersect = other[DELETE][intersect_start - other[POSITION], intersect_end - other[POSITION]]
            raise DeletedDifferentTextFromSameRegion.new unless intersect == other_intersect

            if new_component != ''
              # This could be rewritten similarly to insert v delete, above.
              new_component[POSITION] = transform_position new_component[POSITION], other
              append destination, new_component
            end
          end
          
          destination
        end
      end

      def invert_component(component)
        if component[INSERT]
          {DELETE => component[INSERT], POSITION => component[POSITION]}
        else
          {INSERT => component[DELETE], POSITION => component[POSITION]}
        end
      end

      def invert(operation)
        operation.reverse.each { |component| invert_component component }
      end
    end

  end
end