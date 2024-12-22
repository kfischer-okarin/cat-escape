def try_to_move_cat(stage, cat:, direction:)
  result = []

  cat_entity = stage[:cats][cat]
  cat_position = { x: cat_entity[:x], y: cat_entity[:y] }
  target_x = cat_entity[:x] + direction[:x]
  target_y = cat_entity[:y] + direction[:y]
  target_position = { x: target_x, y: target_y }

  target_cell = stage[:cells][target_x][target_y]
  if target_cell == :wall
    result << {
      type: :cat_bumped_into_wall,
      cat: cat,
      from: cat_position,
      to: target_position
    }
  else
    box_in_cell = find_object(stage, target_position, type: :box)

    cat_moved_event = {
      type: :cat_moved,
      cat: cat,
      from: cat_position,
      to: target_position
    }

    if box_in_cell
      x_behind_box = target_x + direction[:x]
      y_behind_box = target_y + direction[:y]
      position_behind_box = { x: x_behind_box, y: y_behind_box }
      cell_behind_box = stage[:cells][x_behind_box][y_behind_box]
      object_behind_box = find_object(stage, position_behind_box, type: :box)
      cat_behind_box = find_cat_index(stage, position_behind_box)
      if cell_behind_box == :wall || (object_behind_box && object_behind_box[:type] == :box)
        result << {
          type: :cat_bumped_into_box,
          cat: cat,
          from: cat_position,
          to: target_position
        }
      elsif cat_behind_box
        result << {
          type: :pushed_box_into_cat,
          from_cat: cat,
          to_cat: cat_behind_box,
          from: target_position,
          to: position_behind_box
        }
      else
        result << cat_moved_event
        result << {
          type: :box_moved,
          from: box_in_cell.slice(:x, :y),
          to: position_behind_box
        }
      end
    else
      result << cat_moved_event
    end
  end

  result
end
