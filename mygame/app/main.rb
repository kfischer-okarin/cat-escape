require 'app/movement'

STAGE = <<~STAGE.freeze
  XXXXXXXXXX
  XC       X
  XXXXXXXXXX
STAGE

COLORS = {
  orange: { r: 223, g: 113, b: 38 }
}.transform_values(&:freeze).freeze

def tick(args)
  args.state.stage ||= prepare_stage(STAGE)

  input_event = process_input(args)

  handle_input(args, input_event) if input_event

  args.outputs.background_color = { r: 100, g: 100, b: 100 }
  args.outputs.primitives << args.state.stage[:sprites]
  args.outputs.primitives << args.state.stage[:cats].map { |cat|
    {
      x: (cat[:x] * CELL_SIZE) + args.state.stage[:offset_x],
      y: (cat[:y] * CELL_SIZE) + args.state.stage[:offset_y],
      w: CELL_SIZE,
      h: CELL_SIZE,
      path: 'sprites/cat.png',
      **COLORS[:orange]
    }
  }

  args.outputs.debug << "FPS: #{args.gtk.current_framerate}"
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
  end
end

def handle_input(args, input_event)
  case input_event[:type]
  when :move
    movement_results = try_to_move_cat(args.state.stage, cat: 0, direction: input_event[:direction])

    movement_results.each do |result|
      case result[:type]
      when :cat_moved
        args.state.stage[:cats][0][:x] = result[:to][:x]
        args.state.stage[:cats][0][:y] = result[:to][:y]
      end
    end
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
        result[:cats] << { x: x, y: y }
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
    { path: :pixel, r: 255, g: 255, b: 255 }
  end
end

OBJECT_SYMBOLS = {
  'C' => :cat
}.freeze
