module Scenes
  class TitleScreen
    BG_COLOR = { r: 251, g: 225, b: 190 }.freeze

    def tick(args)
      args.outputs.background_color = BG_COLOR
      x = 250
      y = 350
      args.outputs.primitives << {
        x: x, y: y, w: 346 * 2, h: 137 * 2,
        path: 'sprites/title-without-eyes.png'
      }

      render_blinking_eyes(args, x, y)

      args.outputs.primitives << build_label(
        text: 'Press Space to Start',
        x: 640, y: 150, size: 10,
        alignment_enum: 1,
        r: 114, g: 48, b: 14
      )
    end

    private

    def render_blinking_eyes(args, x, y)
      blink_tick = Kernel.tick_count % 300
      h_factor = 1
      case Kernel.tick_count % 300
      when 40..50
        h_factor = Easing.smooth_stop(start_at: 40, end_at: 50, tick_count: blink_tick, power: 2)
      when 60..70
        h_factor = Easing.smooth_stop(start_at: 60, end_at: 70, tick_count: blink_tick, power: 2)
      end

      eyes_x = 136 * 2
      eyes_y = (137 - 75) * 2
      args.outputs.primitives << {
        x: x + eyes_x,
        y: y + eyes_y,
        w: 110 * 2,
        h: 11 * 2 * h_factor,
        source_x: 0,
        source_y: 0,
        source_w: 110,
        source_h: (11 * h_factor).floor,
        path: 'sprites/title-eyes.png'
      }
    end
  end
end
