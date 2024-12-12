def try_to_move_cat(stage, cat:, direction:)
  result = []

  cat_entity = stage[:cats][cat]
  target_x = cat_entity[:x] + direction[:x]
  target_y = cat_entity[:y] + direction[:y]

  target_cell = stage[:cells][target_x][target_y]
  if target_cell == :wall
    result << {
      type: :cat_bumped_into_wall,
      cat: cat,
      from: cat_entity.slice(:x, :y),
      to: { x: target_x, y: target_y }
    }
  else
    box_in_cell = stage[:objects].find { |object|
      object[:x] == target_x && object[:y] == target_y && object[:type] == :box
    }

    cat_moved_event = {
      type: :cat_moved,
      cat: cat,
      from: cat_entity.slice(:x, :y),
      to: { x: target_x, y: target_y }
    }

    if box_in_cell
      cell_behind_box = stage[:cells][target_x + direction[:x]][target_y + direction[:y]]
      if cell_behind_box == :wall
        result << {
          type: :cat_bumped_into_box,
          cat: cat,
          from: cat_entity.slice(:x, :y),
          to: { x: target_x, y: target_y }
        }
      else
        result << cat_moved_event
        result << {
          type: :box_moved,
          from: box_in_cell.slice(:x, :y),
          to: { x: target_x + direction[:x], y: target_y + direction[:y] }
        }
      end
    else
      result << cat_moved_event
    end
  end

  result
end
