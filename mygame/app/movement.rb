def try_to_move_cat(stage, cat:, direction:)
  result = []

  cat_entity = stage[:cats][cat]
  target_x = cat_entity[:x] + direction[:x]
  target_y = cat_entity[:y] + direction[:y]

  result_type = stage[:cells][target_x][target_y] == :wall ? :cat_bumped_into_wall : :cat_moved

  result << {
    type: result_type,
    cat: cat,
    from: cat_entity.slice(:x, :y),
    to: { x: target_x, y: target_y }
  }

  result
end
