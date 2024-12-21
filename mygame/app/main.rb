require 'app/movement'

STAGE = <<~STAGE.freeze
  XXXXXXXXXX
  XCB   C  X
  XXXXXXXXXX
STAGE

COLORS = {
  black: { r: 0, g: 0, b: 0 },
  orange: { r: 223, g: 113, b: 38 }
}.transform_values(&:freeze).freeze

def tick(args)
  setup(args) if args.state.tick_count == 0
  args.state.stage ||= prepare_stage(STAGE)
  args.state.current_cat ||= 0
  args.state.animations ||= []

  input_event = process_input(args)

  handle_input(args, input_event) if input_event && args.state.animations.empty?

  update_animations(args)

  args.outputs.background_color = { r: 100, g: 100, b: 100 }
  args.outputs.primitives << args.state.stage[:sprites]
  args.outputs.primitives << args.state.stage[:objects].map { |object|
    {
      x: (object[:x] * CELL_SIZE) + args.state.stage[:offset_x] + object[:sprite_offset_x],
      y: (object[:y] * CELL_SIZE) + args.state.stage[:offset_y] + object[:sprite_offset_y],
      w: CELL_SIZE,
      h: CELL_SIZE,
      path: 'sprites/crate_42.png',
    }
  }
  args.outputs.primitives << args.state.stage[:cats].map_with_index { |cat, index|
    {
      x: (cat[:x] * CELL_SIZE) + args.state.stage[:offset_x] + cat[:sprite_offset_x],
      y: (cat[:y] * CELL_SIZE) + args.state.stage[:offset_y] + cat[:sprite_offset_y],
      w: CELL_SIZE,
      h: CELL_SIZE,
      path: ['sprites/cat.png', 'sprites/tuxedo-cat.png'][index]
    }
  }

  args.outputs.debug << "FPS: #{args.gtk.current_framerate}"
end

def setup(args)
  args.audio[:bgm] = { input: 'audio/Wholesome.ogg', looping: true }
end

def process_input(args)
  key_down = args.inputs.keyboard.key_down
  if key_down.up
    { type: :move, direction: { x: 0, y: 1 } }
  elsif key_down.down
    { type: :move, direction: { x: 0, y: -1 } }
  elsif key_down.left
    { type: :move, direction: { x: -1, y: 0 } }
  elsif key_down.right
    { type: :move, direction: { x: 1, y: 0 } }
  elsif key_down.tab
    { type: :switch_cat }
  end
end

def handle_input(args, input_event)
  case input_event[:type]
  when :move
    movement_results = try_to_move_cat(
      args.state.stage,
      cat: args.state.current_cat,
      direction: input_event[:direction]
    )

    movement_results.each do |result|
      case result[:type]
      when :cat_moved
        cat_index = result[:cat]
        cat = args.state.stage[:cats][cat_index]
        args.state.animations << {
          type: :move,
          target: cat,
          ticks: 0,
          finished: false,
          direction: input_event[:direction].dup
        }
      when :box_moved
        box = args.state.stage[:objects].find { |object|
          object[:x] == result[:from][:x] && object[:y] == result[:from][:y]
        }
        args.state.animations << {
          type: :move,
          target: box,
          ticks: 0,
          finished: false,
          direction: input_event[:direction].dup
        }
      end
    end
  when :switch_cat
    args.state.current_cat = (args.state.current_cat + 1) % args.state.stage[:cats].size
  end
end

CELL_SIZE = 64

def prepare_stage(stage)
  stage_data = stage.split("\n").map(&:chars)
                    .reverse # make y from bottom to top
                    .transpose # make 2d array have x as first index

  columns = stage_data.size
  rows = stage_data.first.size

  offset_x = (1280 - (columns * CELL_SIZE)).idiv(2)
  offset_y = (720 - (rows * CELL_SIZE)).idiv(2)

  result = {
    cats: [],
    objects: [],
    columns: columns,
    rows: rows,
    cells: [],
    sprites: [],
    offset_x: offset_x,
    offset_y: offset_y
  }

  columns.times do |x|
    data_column = stage_data[x]

    cell_column = []
    result[:cells] << cell_column

    rows.times do |y|
      cell_symbol = data_column[y]
      cell_type = CELL_TYPE_SYMBOLS[cell_symbol]

      cell_column << cell_type

      result[:sprites] << {
        x: (x * CELL_SIZE) + offset_x,
        y: (y * CELL_SIZE) + offset_y,
        w: CELL_SIZE,
        h: CELL_SIZE,
        **cell_sprite(cell_type)
      }

      object_type = OBJECT_SYMBOLS[cell_symbol]
      case object_type
      when :cat
        result[:cats] << { x: x, y: y, sprite_offset_x: 0, sprite_offset_y: 0 }
      when :box
        result[:objects] << { type: object_type, x: x, y: y, sprite_offset_x: 0, sprite_offset_y: 0 }
      end
    end
  end

  result
end

CELL_TYPE_SYMBOLS = {
  'X' => :wall
}.freeze

def cell_sprite(cell_type)
  case cell_type
  when :wall
    { path: :pixel, r: 100, g: 100, b: 100 }
  else
    { path: 'sprites/ground_06.png' }
  end
end

OBJECT_SYMBOLS = {
  'C' => :cat,
  'B' => :box
}.freeze

def update_animations(args)
  args.state.animations.each do |animation|
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
    end
  end

  args.state.animations.reject! { |animation| animation[:finished] }
end
