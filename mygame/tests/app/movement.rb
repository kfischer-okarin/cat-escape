require 'tests/test_helper'

describe 'moving a cat' do
  define_helper(:prepare_plus_stage) do
    prepare_stage(<<~STAGE)
      XXXXX
      XX XX
      X C X
      XX XX
      XXXXX
    STAGE
  end

  [
    { x: 1, y: 0 },
    { x: -1, y: 0 },
    { x: 0, y: 1 },
    { x: 0, y: -1 }
  ].each do |direction|
    it "can move into an empty cell #{direction}" do
      stage = prepare_plus_stage

      result = try_to_move_cat(stage, cat: 0, direction: direction)

      expected = {
        type: :cat_moved,
        cat: 0,
        from: { x: 2, y: 2 },
        to: { x: 2 + direction[:x], y: 2 + direction[:y] }
      }
      assert.includes! result, expected
    end
  end

  it 'cannot move into a wall' do
    stage = prepare_stage(<<~STAGE)
      XXX
      XCX
      XXX
    STAGE

    result = try_to_move_cat(stage, cat: 0, direction: { x: 0, y: 1 })

    expected = {
      type: :cat_bumped_into_wall,
      cat: 0,
      from: { x: 1, y: 1 },
      to: { x: 1, y: 2 }
    }
    assert.includes! result, expected
  end
end
