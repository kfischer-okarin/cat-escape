STAGE = <<~STAGE.freeze
  XXXXXXXXXX
  XC       X
  XXXXXXXXXX
STAGE

def tick(args)
  args.state.stage ||= prepare_stage(STAGE)

  args.outputs.background_color = { r: 100, g: 100, b: 100 }
  args.outputs.primitives << args.state.stage[:sprites]

  args.outputs.debug << "FPS: #{args.gtk.current_framerate}"
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
