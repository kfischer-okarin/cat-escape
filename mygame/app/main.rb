require 'app/animation'
require 'app/movement'

STAGE = <<~STAGE.freeze
  XXXXXXXXXX
  XCB   C  X
  XXXXXXXXXX
STAGE

COLORS = {
  black: { r: 0, g: 0, b: 0 },
  orange: { r: 223, g: 113, b: 38 },
  white: { r: 255, g: 255, b: 255 },
  gray: { r: 100, g: 100, b: 100 }
}.transform_values(&:freeze).freeze

# "Wholesome" Kevin MacLeod (incompetech.com)
# Licensed under Creative Commons: By Attribution 4.0 License
# http://creativecommons.org/licenses/by/4.0/

# Meow sounds by freesound_community from Pixabay
# https://pixabay.com/sound-effects/tom-cat-meow-27989/

CAT_SPRITES = [
  'sprites/cat.png',
  'sprites/tuxedo-cat.png'
].freeze

def tick(args)
  setup(args) if args.state.tick_count == 0
  args.state.stage ||= prepare_stage(STAGE)
  args.state.current_cat ||= 0
  args.state.animations ||= []

  input_event = process_input(args)

  handle_input(args, input_event) if input_event && args.state.animations.empty?

  Animation.update_animations(args.state.animations)

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
    color = index == args.state.current_cat ? COLORS[:white] : COLORS[:gray]
    {
      x: (cat[:x] * CELL_SIZE) + args.state.stage[:offset_x] + cat[:sprite_offset_x],
      y: (cat[:y] * CELL_SIZE) + args.state.stage[:offset_y] + cat[:sprite_offset_y],
      w: cat[:w],
      h: cat[:h],
      path: CAT_SPRITES[index],
      flip_horizontally: !cat[:facing_right],
      **color
    }
  }

  render_current_cat_portrait(args)

  args.outputs.debug << "FPS: #{args.gtk.current_framerate}"
end

def setup(args)
  args.audio[:bgm] = { input: 'audio/Wholesome.ogg', looping: true, gain: 0.3 }
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
        cat = get_cat(args, result[:cat])
        args.state.animations << Animation.build(type: :move, target: cat, direction: input_event[:direction])
        update_cat_facing_direction(cat, input_event[:direction])
      when :box_moved
        box = args.state.stage[:objects].find { |object|
          object[:x] == result[:from][:x] && object[:y] == result[:from][:y]
        }
        args.state.animations << Animation.build(type: :move, target: box, direction: input_event[:direction])
      end
    end
  when :switch_cat
    args.state.current_cat = (args.state.current_cat + 1) % args.state.stage[:cats].size
    args.audio[:meow] = { input: "audio/meow#{rand(8) + 1}.wav" }
    cat = get_cat(args, args.state.current_cat)
    args.state.animations << Animation.build(type: :cat_selected, target: cat)
  end
end

def update_cat_facing_direction(cat, direction)
  if direction[:x].positive?
    cat[:facing_right] = true
  elsif direction[:x].negative?
    cat[:facing_right] = false
  end
end

def get_cat(args, index)
  args.state.stage[:cats][index]
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
        result[:cats] << {
          x: x, y: y,
          sprite_offset_x: 0, sprite_offset_y: 0, w: CELL_SIZE, h: CELL_SIZE,
          facing_right: true
        }
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

def render_current_cat_portrait(args)
  current_cat_sprite = CAT_SPRITES[args.state.current_cat]
  source_w = 39
  source_h = 30
  args.outputs.primitives << {
    x: 0,
    y: 0,
    w: source_w * 5,
    h: source_h * 5,
    path: current_cat_sprite,
    source_x: 23,
    source_y: 20,
    source_w: source_w,
    source_h: source_h
  }
end
