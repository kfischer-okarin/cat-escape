STAGE = <<~STAGE.freeze
  XXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXX
  XXXXX        XXXXXXX
  XXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXX
STAGE

def tick(args)
  args.state.stage ||= prepare_stage(STAGE)

  args.outputs.primitives << args.state.stage.flat_map { |column|
    column.map { |cell|
      cell[:sprite]
    }
  }

  args.outputs.debug << "FPS: #{args.gtk.current_framerate}"
end

CELL_SIZE = 64
OFFSET_Y = (720 - (720.idiv(CELL_SIZE) * CELL_SIZE)).idiv(2)

def prepare_stage(stage)
  cells = stage.split("\n").map(&:chars)
               .reverse # make y from bottom to top
               .transpose # make 2d array have x as first index

  cells.map_with_index { |column, x|
    column.map_with_index { |cell, y|
      {
        sprite: {
          x: x * CELL_SIZE,
          y: (y * CELL_SIZE) + OFFSET_Y,
          w: CELL_SIZE,
          h: CELL_SIZE,
          **cell_sprite(cell)
        }
      }
    }
  }
end

def cell_sprite(cell)
  case cell
  when 'X'
    { path: :pixel, r: 100, g: 100, b: 100 }
  when ' '
    { path: :pixel, r: 255, g: 255, b: 255 }
  end
end
