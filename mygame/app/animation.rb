module Animation
  class << self
    def build(values)
      values.merge(ticks: 0, finished: false)
    end

    def update_animations(animations)
      animations.each do |animation|
        handler_method_name = "handle_#{animation[:type]}_animation"
        animation[:ticks] += 1
        if respond_to?(handler_method_name)
          send(handler_method_name, animation)
        else
          animation[:finished] = true
          $gtk.notify! "No handler for animation type: #{animation[:type]}"
        end
      end

      animations.reject! { |animation| animation[:finished] }
    end

    private

    def handle_move_animation(animation)
      target = animation[:target]
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
    end

    def handle_cat_selected_animation(animation)
      target = animation[:target]
      duration = 20
      factor = parabol_easing(animation[:ticks], duration)
      w = CELL_SIZE - (factor * 10).floor
      h = CELL_SIZE + (factor * 10).floor
      target[:sprite_offset_x] = (CELL_SIZE - w).idiv(2)
      target[:w] = w
      target[:h] = h
      return unless animation[:ticks] == duration

      target[:w] = CELL_SIZE
      target[:h] = CELL_SIZE
      target[:sprite_offset_x] = 0
      animation[:finished] = true
    end

    def handle_angry_cat_animation(animation)
      handle_cat_selected_animation(animation)
    end

    def parabol_easing(tick, duration)
      t = tick / duration
      4 * t * (1 - t)
    end
  end
end
