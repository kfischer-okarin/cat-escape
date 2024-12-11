STAGE = <<~STAGE.freeze
  XXXXXXXXXX
  X        X
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

  stage_sprites = []
  cells = []
  columns.times do |col|
    data_column = stage_data[col]

    cell_column = []
    cells << cell_column

    rows.times do |row|
      cell_type_symbol = data_column[row]
      cell_type = CELL_TYPE_SYMBOLS[cell_type_symbol]

      cell_column << cell_type

      stage_sprites << {
        x: (col * CELL_SIZE) + offset_x,
        y: (row * CELL_SIZE) + offset_y,
        w: CELL_SIZE,
        h: CELL_SIZE,
        **cell_sprite(cell_type)
      }
    end
  end

  {
    columns: columns,
    rows: rows,
    cells: cells,
    sprites: stage_sprites,
    offset_x: offset_x,
    offset_y: offset_y
  }
end

CELL_TYPE_SYMBOLS = {
  'X' => :wall,
  ' ' => :empty
}.freeze

def cell_sprite(cell_type)
  case cell_type
  when :wall
    { path: :pixel, r: 100, g: 100, b: 100 }
  when :empty
    { path: :pixel, r: 255, g: 255, b: 255 }
  end
end
