require 'app/animation'
require 'app/movement'

STAGES = [
  (
    <<~STAGE.freeze
      XXXXXXXXXXX
      XXXXCXXXXXX
      XXXX X   XX
      XC BB    EX
      XXXX X   XX
      XXXXXXXXXXX
    STAGE
  ),
  (
    <<~STAGE.freeze
      XXXXXXX
      XC   EX
      XXBXBXX
      XX C XX
    STAGE
  ),
  (
    <<~STAGE.freeze
      XXXXXXX
      XCBC XX
      XXBXBXX
      XX X XX
      X B  EX
      XX X XX
    STAGE
  ),
]

$gtk.reset

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

# Angry cat sounds by freesound_community from Pixabay
# https://pixabay.com/sound-effects/very-angry-cat-101289/

# Box move sound by freesound_community from Pixabay
# https://pixabay.com/sound-effects/chair-sliding-28432/

# m6x11plus font by Daniel Linssen
# https://managore.itch.io/m6x11

# Box sprite by Kenney.nl
# https://kenney.nl/assets/sokoban

# Icons by Kenney.nl
# https://kenney.nl/assets/board-game-icons
# https://kenney.nl/assets/input-prompts

CAT_SPRITES = [
  'sprites/cat.png',
  'sprites/tuxedo-cat.png'
].freeze

SCARED_CAT_SPRITES = [
  'sprites/cat-scared.png',
  'sprites/tuxedo-cat-scared.png'
].freeze

def tick(args)
  setup(args, stage_number: 0) if Kernel.tick_count.zero?

  input_event = process_input(args)

  gameplay_tick(args, input_event: input_event)
  args.outputs.debug << "FPS: #{args.gtk.current_framerate}"
end

def setup(args, stage_number:)
  args.state.stage_number = stage_number
  args.state.stage = prepare_stage(STAGES[stage_number])
  args.state.current_cat = 0
  args.state.animations = []
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
  elsif key_down.r
    { type: :restart }
  end
end

def gameplay_tick(args, input_event: nil)
  handle_gameplay_input(args, input_event) if input_event && args.state.animations.empty?
  handle_exited_cat(args)
  Animation.update_animations(args.state.animations)

  render_stage(args, args.state.stage)
  render_current_cat_portrait(args)
  render_ui(args)
end

def handle_gameplay_input(args, input_event)
  case input_event[:type]
  when :move
    movement_results = try_to_move_cat(
      args.state.stage,
      cat: args.state.current_cat,
      direction: input_event[:direction]
    )
    cat = get_cat(args, args.state.current_cat)
    update_cat_facing_direction(cat, input_event[:direction])


    movement_results.each do |result|
      case result[:type]
      when :cat_moved
        args.state.animations << Animation.build(type: :move, target: cat, direction: input_event[:direction])
      when :box_moved
        args.audio[:box_moved] = { input: 'audio/move_box.wav', gain: 0.5 }
        args.state.animations << Animation.build(
          type: :move,
          target: find_object(args.state.stage, result[:from], type: :box),
          direction: input_event[:direction]
        )
      when :pushed_box_into_cat
        args.audio[:angry_cat] = { input: "audio/angry_cat#{rand(3) + 1}.wav" }
        other_cat = get_cat(args, result[:to_cat])
        update_cat_facing_direction(other_cat, input_event[:direction].merge(x: -input_event[:direction][:x]))
        args.state.animations << Animation.build(type: :scared_cat, target: cat)
        args.state.animations << Animation.build(type: :angry_cat, target: other_cat)
        args.state.animations << Animation.build(
          type: :canceled_move,
          target: cat,
          direction: input_event[:direction]
        )
        args.state.animations << Animation.build(
          type: :canceled_move,
          target: find_object(args.state.stage, result[:from], type: :box),
          direction: input_event[:direction]
        )
      when :cat_bumped_into_cat
        args.audio[:angry_cat] = { input: "audio/angry_cat#{rand(3) + 1}.wav" }
        other_cat = get_cat(args, result[:to_cat])
        update_cat_facing_direction(other_cat, input_event[:direction].merge(x: -input_event[:direction][:x]))
        args.state.animations << Animation.build(type: :scared_cat, target: cat)
        args.state.animations << Animation.build(type: :angry_cat, target: other_cat)
        args.state.animations << Animation.build(
          type: :canceled_move,
          target: cat,
          direction: input_event[:direction]
        )
      when :cat_exited
        args.audio[:meow] = { input: "audio/meow#{rand(8) + 1}.wav" }
        args.state.animations << Animation.build(type: :exit, target: cat, audio: args.audio)
      end
    end
  when :switch_cat
    switch_cat(args)
  when :restart
    setup(args, stage_number: args.state.stage_number)
  end
end

def switch_cat(args, skip_animation: false)
  return if other_cat_exited?(args)

  new_cat_index = (args.state.current_cat + 1) % args.state.stage[:cats].size
  new_cat = get_cat(args, new_cat_index)

  args.state.current_cat = new_cat_index
  return if skip_animation

  args.audio[:meow] = { input: "audio/meow#{rand(8) + 1}.wav" }
  args.state.animations << Animation.build(type: :cat_selected, target: new_cat)
end

def other_cat_exited?(args)
  other_cat_index = 1 - args.state.current_cat
  args.state.stage[:cats][other_cat_index][:exit]
end

def handle_exited_cat(args)
  cat = get_cat(args, args.state.current_cat)
  return unless cat[:exit]

  all_cats_exited = args.state.stage[:cats].all? { |cat| cat[:exit] }
  if all_cats_exited
    args.state.stage_number += 1
    setup(args, stage_number: args.state.stage_number)
  else
    switch_cat(args, skip_animation: true)
  end
end

def find_object(stage, position, type: nil)
  stage[:objects].find { |object|
    object[:x] == position[:x] && object[:y] == position[:y] && (type.nil? || object[:type] == type)
  }
end

def find_cat(stage, position)
  stage[:cats].find { |cat| cat[:x] == position[:x] && cat[:y] == position[:y] && !cat[:exit] }
end

def find_cat_index(stage, position)
  stage[:cats].index { |cat| cat[:x] == position[:x] && cat[:y] == position[:y] && !cat[:exit] }
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
          alpha: 255, exit: false,
          facing_right: true,
          scared: false
        }
      when :box, :exit
        result[:objects] << { type: object_type, x: x, y: y, sprite_offset_x: 0, sprite_offset_y: 0 }
      end
    end
  end

  result
end

def render_stage(args, stage)
  args.outputs.background_color = { r: 100, g: 100, b: 100 }
  args.outputs.primitives << stage[:sprites]
  args.outputs.primitives << stage[:objects].map { |object|
    {
      x: (object[:x] * CELL_SIZE) + stage[:offset_x] + object[:sprite_offset_x],
      y: (object[:y] * CELL_SIZE) + stage[:offset_y] + object[:sprite_offset_y],
      w: CELL_SIZE,
      h: CELL_SIZE,
      **object_sprite(object)
    }
  }
  args.outputs.primitives << stage[:cats].map_with_index { |cat, index|
    color = index == args.state.current_cat ? COLORS[:white] : COLORS[:gray]
    {
      x: (cat[:x] * CELL_SIZE) + stage[:offset_x] + cat[:sprite_offset_x],
      y: (cat[:y] * CELL_SIZE) + stage[:offset_y] + cat[:sprite_offset_y],
      w: cat[:w],
      h: cat[:h],
      path: cat_sprite(cat, index),
      flip_horizontally: !cat[:facing_right],
      a: cat[:alpha],
      **color
    }
  }
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
  'B' => :box,
  'E' => :exit
}.freeze

def object_sprite(object)
  case object[:type]
  when :box
    { path: 'sprites/crate_42.png' }
  when :exit
    { path: 'sprites/flag_square.png', r: 255, g: 255, b: 0 }
  end
end

def render_current_cat_portrait(args)
  cat = get_cat(args, args.state.current_cat)
  source_w = 39
  source_h = 30
  args.outputs.primitives << {
    x: 0,
    y: 0,
    w: source_w * 5,
    h: source_h * 5,
    path: cat_sprite(cat, args.state.current_cat),
    source_x: 23,
    source_y: 20,
    source_w: source_w,
    source_h: source_h
  }
end

def render_ui(args)
  unless other_cat_exited?(args)
    args.outputs.primitives << {
      x: 50,
      y: 154,
      w: 32,
      h: 32,
      path: 'sprites/arrow_reserve.png'
    }
    args.outputs.primitives << {
      x: 80,
      y: 138,
      w: 64,
      h: 64,
      path: 'sprites/keyboard_tab.png'
    }
  end

  args.outputs.primitives << {
    x: 0,
    y: 656,
    w: 64,
    h: 64,
    path: 'sprites/keyboard_r.png'
  }
  args.outputs.primitives << {
    x: 64,
    y: 706,
    text: 'Restart',
    size_px: 36,
    r: 255, g: 255, b: 255,
    font: 'fonts/m6x11plus.ttf'
  }
end

def cat_sprite(cat, cat_index)
  sprite_array = cat[:scared] ? SCARED_CAT_SPRITES : CAT_SPRITES
  sprite_array[cat_index]
end
