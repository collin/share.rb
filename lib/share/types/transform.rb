module Share::Types::Transform
  LEFT = 'left'
  RIGHT = 'right'

  def transform_component_x(left, right, dest_left, dest_right)
    transform_component dest_left, left, right, 'left'
    transform_component dest_right, right, left, 'right'
    nil
  end

  def transform_x(left, right)
    check_valid_operation(left)
    check_valid_operation(right)

    new_right = []

    right.each do |component|
      # puts "RIGHT EACH"
      new_left = []

      # puts ["left",left].inspect
      left.each_with_index do |left_component, index|
        # puts "LEFT EACH"
        # puts ["index", index].inspect
        next_component = []

        # puts ["next_component pre", new_left, next_component].inspect
        transform_component_x left_component, component, new_left, next_component

        # puts ["next_component aft", new_left, next_component].inspect
        if next_component.length == 1
          component = next_component.first
        elsif next_component.length == 0
          # puts ["next c length is 0", new_left, left.slice(index + 1, left.length)].inspect
          left.slice(index + 1, left.length).each {|_component| _append new_left, _component }
          component = nil
          break
        else
          _left, _right = transform_x left.slice(index + 1, left.length), next_component
          _append new_left, _left
          _append new_right, _right
          component = nil
          break
        end
            
      end

      _append new_right, component if component
      left = new_left
    end

    [left, new_right]
  end

  def transform(operation, other, type)
    unless [LEFT, RIGHT].include?(type)
      raise ArgumentError.new("type must be 'left' or 'right'")  
    end

    return operation if other.length == 0
    # TODO: Benchmark with and without this line. I _think_ it'll make a big difference...?

    if operation.length == 1 and other.length == 1
      transform_component [], operation[0], other[0], type
    end

    if type == LEFT
      transform_x(operation, other).first
    else
      transform_x(other, operation).last
    end
  end
end