module Animation
  class << self
    def build(values)
      values.merge(ticks: 0, finished: false)
    end

    def update_animations(args, animations)
      animations.each do |animation|
        handler_method_name = "handle_#{animation[:type]}_animation"
        animation[:ticks] += 1
        if respond_to?(handler_method_name)
          send(handler_method_name, args, animation)
        else
          animation[:finished] = true
          $gtk.notify! "No handler for animation type: #{animation[:type]}"
        end
      end

      animations.reject! { |animation| animation[:finished] }
    end

    private

    def handle_move_animation(_args, animation)
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

    def handle_canceled_move_animation(_args, animation)
      target = animation[:target]
      duration = 20
      factor = parabol_easing(animation[:ticks], duration)
      if animation[:ticks] == duration
        target[:sprite_offset_x] = 0
        target[:sprite_offset_y] = 0
        animation[:finished] = true
      else
        target[:sprite_offset_x] = (animation[:direction][:x] * CELL_SIZE * factor * 0.3).floor
        target[:sprite_offset_y] = (animation[:direction][:y] * CELL_SIZE * factor * 0.3).floor
      end
    end

    def handle_cat_selected_animation(_args, animation)
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

    def handle_angry_cat_animation(args, animation)
      handle_cat_selected_animation(args, animation)
    end

    def handle_scared_cat_animation(_args, animation)
      case animation[:ticks]
      when 3
        animation[:target][:scared] = true
      when 20
        animation[:target][:scared] = false
        animation[:finished] = true
      end
    end

    def handle_exit_animation(args, animation)
      duration = 20
      factor = Easing.smooth_step(start_at: 0, end_at: duration, tick_count: animation[:ticks], power: 2)
      if animation[:ticks] == duration
        animation[:target][:alpha] = 0
        animation[:target][:exit] = true
        animation[:finished] = true

        handle_exited_cat(args)
      else
        animation[:target][:alpha] = 255 - (factor * 255).floor
      end
    end

    def handle_level_transition_animation(args, animation)
      args.state.screen_overlays.reject! { |overlay| overlay[:level_transition] }

      length = 40
      first_half_end = length
      second_half_start = length + 10
      animation_end = second_half_start + length
      case animation[:ticks]
      when 0...second_half_start
        factor = Easing.smooth_stop(start_at: 0, end_at: first_half_end, tick_count: animation[:ticks], power: 2)
        args.state.screen_overlays.concat(transition_mask(1 - factor))
        setup(args, stage_number: args.state.stage_number) if animation[:ticks] == first_half_end
      when second_half_start...animation_end
        factor = Easing.smooth_start(
          start_at: second_half_start,
          end_at: animation_end,
          tick_count: animation[:ticks],
          power: 2
        )
        args.state.screen_overlays.concat(transition_mask(factor))
      else
        animation[:finished] = true
      end
    end

    def transition_mask(zoom_factor)
      center_size = 1024 * 10 * zoom_factor
      half_center_size = center_size.idiv(2)
      base = {
        level_transition: true,
        x: 0, y: 0, w: 1280, h: 720,
        path: :pixel,
        **COLORS[:orange]
      }
      [
        {
          **base,
          x: 640 - half_center_size,
          y: 360 - half_center_size,
          w: center_size,
          h: center_size,
          path: 'sprites/paw-mask.png',
        },
        # bottom
        {
          **base,
          h: 360 - half_center_size
        },
        # top
        {
          **base,
          y: 360 + half_center_size,
          h: 360 - half_center_size,
        },
        # left
        {
          **base,
          w: 640 - half_center_size,
        },
        # right
        {
          **base,
          x: 640 + half_center_size,
          w: 640 - half_center_size,
        }
      ]
    end

    def parabol_easing(tick, duration)
      t = tick / duration
      4 * t * (1 - t)
    end
  end
end
