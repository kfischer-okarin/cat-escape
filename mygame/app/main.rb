STAGE = <<~STAGE.freeze
  XXXXXXXXXX
  X        X
  XXXXXXXXXX
STAGE

def tick(args)
  args.state.stage ||= prepare_stage(STAGE)

  args.outputs.primitives << args.state.stage[:cells].flat_map { |column|
    column.map { |cell|
      cell[:sprite]
    }
  }

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

  cells = (0...columns).map { |col|
    column = stage_data[col]
    x = (col * CELL_SIZE) + offset_x

    (0...rows).map { |row|
      cell_type = column[row]
      {
        sprite: {
          x: x,
          y: (row * CELL_SIZE) + offset_y,
          w: CELL_SIZE,
          h: CELL_SIZE,
          **cell_sprite(cell_type)
        }
      }
    }
  }

  {
    columns: columns,
    rows: rows,
    cells: cells,
    offset_x: offset_x,
    offset_y: offset_y
  }
end

def cell_sprite(cell_type)
  case cell_type
  when 'X'
    { path: :pixel, r: 100, g: 100, b: 100 }
  when ' '
    { path: :pixel, r: 255, g: 255, b: 255 }
  end
end
