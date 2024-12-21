module Animation
  class << self
    def build(values)
      values.merge(ticks: 0, finished: false)
    end

    def update_animations(animations)
      animations.each do |animation|
        case animation[:type]
        when :move
          target = animation[:target]
          animation[:ticks] += 1
          duration = 20
          factor = Easing.smooth_step(start_at: 0, end_at: duration, tick_count: animation[:ticks], power: 2)
          if animation[:ticks] == duration
            target[:sprite_offset_x] = 0
            target[:sprite_offset_y] = 0
            target[:x] += animation[:direction][:x]
            target[:y] += animation[:direction][:y]
            animation[:finished] = true
          else
            target[:sprite_offset_x] = (animation[:direction][:x] * CELL_SIZE * factor).floor
            target[:sprite_offset_y] = (animation[:direction][:y] * CELL_SIZE * factor).floor
          end
        when :cat_selected
          target = animation[:target]
          animation[:ticks] += 1
          duration = 20
          factor = parabol_easing(animation[:ticks], duration)
          w = CELL_SIZE - (factor * 10).floor
          h = CELL_SIZE + (factor * 10).floor
          target[:sprite_offset_x] = (CELL_SIZE - w).idiv(2)
          target[:w] = w
          target[:h] = h
          if animation[:ticks] == duration
            target[:w] = CELL_SIZE
            target[:h] = CELL_SIZE
            target[:sprite_offset_x] = 0
            animation[:finished] = true
          end
        end
      end

      animations.reject! { |animation| animation[:finished] }
    end

    private

    def parabol_easing(tick, duration)
      t = tick / duration
      4 * t * (1 - t)
    end
  end
end
