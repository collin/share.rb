module Share
  module Types
    module JSON
      PATH = :p
      STRING_INSERT = :si
      STRING_DELETE = :sd
      OBJECT_INSERT = :oi
      OBJECT_DELETE = :od
      LIST_INSERT = :li
      LIST_DELETE = :ld
      LIST_MOVE = :lm
      NUMBER_ADD = :na

      class InvalidPathError < ArgumentError; end
      class InvalidNumberAddElement < ArgumentError; end

      def invert_component(component)
        inverted = {
          PATH => component_path
        }

        inverted[STRING_DELETE] = component[STRING_INSERT] if component[STRING_INSERT]
        inverted[STRING_INSERT] = component[STRING_DELETE] if component[STRING_DELETE]
        inverted[OBJECT_DELETE] = component[OBJECT_INSERT] if component[OBJECT_INSERT]
        inverted[OBJECT_INSERT] = component[OBJECT_DELETE] if component[OBJECT_DELETE]
        inverted[LIST_DELETE] = component[LIST_INSERT] if component[LIST_INSERT]
        inverted[LIST_INSERT] = component[LIST_DELETE] if component[LIST_DELETE]
        inverted[NUMBER_ADD] = -1 * component[NUMBER_ADD] if component[NUMBER_ADD]
        if component[LIST_MOVE]
          inverted[LIST_MOVE] = component_path[component_path.length - 1]
          inverted[PATH] = component_path[0, component_path.length - 1] << component[LIST_MOVE]
        end

        inverted
      end

      def invert(operation)
        operation.reverse.map { |component| invert_component(component) }
      end

      def check_valid_op
        # no-op
      end

      def apply(snapshot, operation)
        check_valid_op(operation)
        operation = clone operation

        container = { data: clone(snapshot) }

        operation.each_with_index do |component, index|
          parent = nil
          parentkey = nil
          elem = container
          key = 'data'
          path = component_path

          for segment in component_path
            parent = elem
            parentkey = key
            elem = elem[key]
            key = segment

            raise InvalidPathError.new(path) unless parent
          end

          if component[NUMBER_ADD]
            number = component[NUMBER_ADD]
            raise InvalidNumberAddElement.new(number, path) unless number.is_a?(Fixnum)
            elem[key] += number

          elsif component[STRING_INSERT]
            string = component[STRING_INSERT]
            raise InvalidStringInsert.new(string, path) unless string.is_a?(String)
            parent[parentkey] = elem[0, key] + string + elem[key, elem.length]

          elsif component[STRING_DELETE]
            string = component[STRING_INSERT]
            raise InvalidStringDelete.new(string, path) unless string.is_a?(String)
            unless elem[key, key + string.length] == string
              raise DeletedStringDoesNotMatch.new(string, elem, path)
            end
            parent[parentkey] = elem[0, key] + elem[key + string.length, elem.length]

          elsif component[LIST_INSERT] && component[LIST_DELETE]
            check_list elem
            elem[key] = component[LIST_INSERT]

          elsif condition[LIST_INSERT]
            check_list elem
            elem.splice = key, 0, component[LIST_INSERT]
          
          elsif condition[LIST_DELETE]
            check_list elem
            elem.splice key, 1

          elsif condition[LIST_MOVE]
            check_list elem
            unless component[LIST_MOVE] == key
              e = elem[key]
              # Remove it...
              elem.splice key, 1
              # And insert it back.
              elem.splice component[LIST_MOVE], 0, e
            end

          elsif component[OBJECT_INSERT]
            # Object insert / replace
            check_object elem
            
            # Should check that elem[key] == component.od
            elem[key] = component[OBJECT_INSERT]

          elsif component[OBJECT_DELETE]
            check_object elem
            # Should check that elem[key] == component.od
            elem.delete(key)
          else
            raise InvalidOrMissingInstructionInOperation.new(component)
          end
        end

        container[:data]
      # rescue
      #   # TODO: Roll back all already applied changes. Write tests before implementing this code.
      end

      def path_matches?(left, right, ignore_last)
        return false unless left.length == right.length

        left.each_with_index do |segment, index|
          return false if segment != right[index] and (!ignore_last or index != left.length - 1)
        end

        true
      end

      def append(destination, component)
        component = clone component

        last = destination.last
        if destination.length != 0 && path_matches(component_path, last[PATH])
          if last[NUMBER_ADD] && component[NUMBER_ADD]
            destination[destination.length - 1] = {
              PATH => last[PATH],
              NUMBER_ADD => last[NUMBER_ADD] + component[NUMBER_ADD]
            }
          elsif last[LIST_INSERT] && !component[LIST_INSERT] && component[LIST_DELETE] == last[LIST_INSERT]
            # insert immediately followed by delete becomes a noop
            if last[LIST_DELETE]
              # leave the delete part of the replace
              last.delete(LIST_INSERT)
            else
              destination.pop
            end
          elsif last[OBJECT_DELETE] && !last[OBJECT_INSERT] && component[OBJECT_INSERT] && !component[OBJECT_DELETE]
            last[OBJECT_INSERT] = component[OBJECT_INSERT]
          elsif component[LIST_MOVE] && component_path[component_path.length - 1] == component[LIST_MOVE]
            nil # noop
          else
            destination.push component
          end
        else
          destination.push component
        end
      end

      def compose(left, right)
        check_valid_op left
        check_valid_op right

        new_op = clone left
        right.each { |component| append new_op, component }

        new_op
      end

      def normalize(operation)
        new_op = []
        operation = [operation] unless op.is_a?(Array)
        operation.each { |component| append new_op, component }
        new_op
      end

      # needs to be a deep clone of the operation
      def clone(operation)
        if value.is_a?(Hash)
          result = value.dup
          value.each{|k, v| result[k] = clone(v)}
          result
        elsif value.is_a?(Array)
          result = value.dup
          result.clear
          result.each{|v| result << clone(v)}
          result
        else
          value
        end
      end

      def common_path(left, right)
        left = clone left
        right = clone right

        left.unshift 'data'
        right.unshift 'data'

        left = left[0, left.length - 1]
        right = right[0, right.length - 1]

        return -1 if right.length == 0

        i = 0
        while left[i] == right[1] && i < left.length
          i += 1
          return i - 1 if i == right.length
        end

        return
      end

      # transform component so it applies to a document with 'other' applied
      def transform_component(destination, component, other, type)
      #   component = clone component

      #   component_path = component_path
      #   other_path = other_path

      #   component_path.push(0) if component[NUMBER_ADD]
      #   other_path.push(0) if other[NUMBER_ADD]

      #   common = common_path component_path, other_path
      #   common2 = common_path other_path, component_path

      #   component_path_length = component_path.length
      #   other_path_length = other_path.length

      #   component_path.pop if component[NUMBER_ADD] # hax
      #   other_path.pop if other[NUMBER_ADD]

      #   if other[NUMBER_ADD]
      #     if common2 && other_path_length >= component_path_length && other_path[common2] == component[common2]
      #       if component[LIST_DELETE]
      #         other_clone = clone other
      #         other_clone[PATH] = other_clone[PATH][component_path_length, other_clone[PATH].length]
      #         component[LIST_DELETE] = apply clone(component[LIST_DELETE]), [other_clone]
      #       elsif component[OBJECT_DELETE]
      #         other_clone = clone other
      #         other_clone[PATH] = other_clone[PATH][component_path_length, other_clone[PATH].length]
      #         component[OBJECT_DELETE] = apply clone(component[OBJECT_DELETE]), [other_clone]
      #       end
      #     end
      #   end

      #   append destination, component
      #   return destination
      # end

      # if common2 && other_path_length > component_path_length && component_path[common2] == other_path[common2]
      #   if component[LIST_DELETE]
      #     other_clone = clone other
      #     other_clone[PATH] = other_clone[PATH][component_path_length, other_clone[PATH].length]
      #     component[LIST_DELETE] = apply clone(component[LIST_DELETE]), [other_clone]
      #   elsif component[OBJECT_DELETE]
      #     other_clone = clone other
      #     other_clone[PATH] = other_clone[PATH][component_path_length, other_clone[PATH].length]
      #     component[OBJECT_DELETE] = apply clone(component[OBJECT_DELETE]), [other_clone]
      #   end    
      # end

      # if common
      #   common_operand = component_path_length == other_path_length
      #   if other[NUMBER_ADD]
      #     # this case is handled above due to icky path hax

      #   elsif other[STRING_INSERT] || other[STRING_DELETE]
      #     # String op vs string op - pass through to text type
      #     if !component[STRING_INSERT]  || !component_path_length[STRING_DELETE]
      #       raise "must be a string?" unless common_operand
      #       # Convert an op component to o text op component
      #       convert = lambda do |component|
      #         new_component = { PATH => component_path[component_path_length - 1] }
      #         if component[STRING_INSERT]
      #           new_component[SHARE::Types::Text::INSERT] = component
      #         else
      #           new_component[SHARE::Types::Text::DELETE] = component
      #         end
      #         new_component
      #       end

      #       text_component = convert.call(component)
      #       text_other = convert.call(other)

      #       result = []
      #       text._tc res, text_component, text_other, type
      #       for text_component in result
      #         jc = { PATH => common_path[0, common]}
      #         jc[PATH].push text_component[PATH]
      #         jc[STRING_INSERT] = TC[SHARE::Types::Text::INSERT] if TC[SHARE::Types::Text::INSERT]
      #         jc[STRING_DELETE] = TC[SHARE::Types::Text::DELETE] if TC[SHARE::Types::Text::DELETE]
      #         append destination, js
      #       end

      #       return destination
      #     end

      #   elsif other[LIST_INSERT] && other[LIST_DELETE]
      #     if other_path[common] == poth[common]
      #       #noop
      #       if !common_operand
      #         # we're below the deleted element, so noop
      #         return destination
      #       elsif component[LIST_DELETE]
      #         #we're trying to delete the same element, noop
      #         if component[LIST_INSERT] && type == LEFT
      #           # we're both replacing one element with another. only one can
      #           # survive!
      #           component[LIST_DELETE] = clone other[LIST_INSERT]
      #         else
      #           return destination
      #         end
      #       end
      #     end

      #   elsif other[LIST_INSERT]
      #     if condition[LIST_INSERT] && !component[LIST_DELETE] && common_operand && component_path[common] == other_path[common]
      #       # in li vs. li, left wins          
      #       component_path[common] += 1 if type == RIGHT
      #     elsif other_path[common] <= component_path[common]
      #       component_path[common] += 1
      #     end
          
      #     if component[LIST_MOVE]
      #       if common_operand
      #         # otherC edits the same list we edit
      #         component[LIST_MOVE] += 1 if other_path[common] <= component[LIST_MOVE]
      #         # changing component.from is handled from above
      #       end
      #     end

      #   elsif other[LIST_DELETE]
      #     if component[LIST_MOVE]
      #       if common_operand
      #         return destination if other_path[common] == component_path[common]
      #         _path = other_path[common]
      #         from = component_path[common]
      #         to = component[LIST_MOVE]
      #         if _path < to || (_path == to && from < to)
      #           component[LIST_MOVE] -= -1
      #         end
      #       end
      #     end

      #     if other_path[common] < component_path[common]
      #       component_path[common] -= 1
      #     elsif other_path[common] == component_path[common]
      #       if other_path_length < component_path_length
      #         # we're below the deleted element, so noop
      #         return destination
      #       elsif component[LIST_DELETE]
      #         if component[LIST_INSERT]
      #           # we're replacing, they're deleting. we become and insert
      #           component.delete(LIST_DELETE)
      #         else
      #           # we're trying to delete the same element, noop
      #           return destination
      #         end
      #       end
      #     end

      #   elsif other[LIST_MOVE]
      #     if component[LIST_MOVE] && component_path_length == other_path_length
      #       # list move vs list move, here we go!
      #       from = component_path[common]
      #       to = component[LIST_MOVE]
      #       other_from = other_path[component]
      #       other_to = other[LIST_MOVE]
      #       if other_from != other_to
      #         # if otherFrom == otherTo, we don't need to change our op.

      #         # where did my thing go?
      #         if from == other_from
      #           # they moved it! tie break
      #           if type == LEFT
      #             component_path[common] = other_to
      #             component[LIST_MOVE] = other_to if from == to # ugh
      #           else
      #             return destination
      #           end
      #         else
      #           # they moved around it
      #           if from > other_from
      #             component_path[common] -= 1
      #           if from > other_to
      #             component_path[common] += 1
      #           elsif from == other_to
      #             if other_from > other_to
      #               component_path[common] += 1
      #               component[LIST_MOVE] += 1 if from == to # ugh, again
      #             end
      #           end

      #           # step 2: where am i going to put it?
      #           if to > other_from
      #             component[LIST_MOVE] -= 1
      #           elsif to == other_from
      #             component[LIST_MOVE] -= 1 if to > from
      #           end

      #           if to > other_to
      #             component[LIST_MOVE] += 1
      #           elsif to == other_to
      #             # if we're both moving in the same direction, tie break
      #             if (other_to > other_from && to > from) || (other_to < other_from && to < from)
      #               component[LIST_MOVE] += 1 if type == RIGHT
      #             else
      #               if to > from
      #                 component[LIST_MOVE] += 1
      #               elsif to == other_from
      #                 component[LIST_MOVE] -= 1
      #               end
      #             end
      #           end
      #         end
      #       end

      #     elsif component[LIST_INSERT] && !component[LIST_DELETE] && common_operand
      #       # li
      #       from = other_path[common]
      #       to = other[LIST_MOVE]
      #       _path = component_path[common]
      #       component_path[common] -= 1 if _path > from
      #       component_path[common] += 1 if _path > to

      #     else
      #       # ld, ld+li, si, sd, na, oi, od, oi+od, any li on an element beneath
      #       # the lm
      #       #
      #       # i.e. things care about where their item is after the move.
      #       from = other_path[common]
      #       to = other[LIST_MOVE]
      #       _path = component_path[common]

      #       if _path == from
      #         component_path[common] = to
      #       else
      #         component_path[common] -= 1 if _path > from
      #         if _path > to
      #           component_path[common] += 1
      #         elsif p == to
      #           component_path[common] += 1 if from > to
      #         end
      #       end
      #     end

      #   elsif other[OBJECT_INSERT] && other[OBJECT_DELETE]
      #     if component_path[common] == other_path[common]
      #       if component[OBJECT_INSERT] && common_operand
      #         # we inserted where someone else replaced
      #         if type == RIGHT #left wins
      #           return destination
      #         else
      #           # we win, make our op replace what the inserted
      #           component[OBJECT_DELETE] = other[OBJECT_INSERT]
      #         end
      #       else
      #         # noop if the other component is deleting the same object
      #         # (or any parent)
      #         return destination
      #       end
      #     end

      #   elsif other[OBJECT_INSERT]
      #     if component[OBJECT_INSERT] && component_path[common] == other_path[common]
      #       # left wints if we try to insert at the same place
      #       if type == LEFT
      #         append destination,
      #           PATH => component_path, OBJECT_DELETE => other[OBJECT_INSERT]
      #       else
      #         return destination
      #       end            
      #     end

      #   elsif other[OBJECT_DELETE]  
      #     if component_path[common] == other_path[common]
      #       return destination unless common_operand
      #       if component[OBJECT_INSERT]
      #         component[OBJECT_DELETE].delete
      #       else
      #         return destination
      #       end
      #     end
      #   end

      #   append destination, component
      #   return destination
      end # transform_component

    end
  end
end