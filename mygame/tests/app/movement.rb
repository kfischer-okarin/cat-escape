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
      original_position = stage[:cats][0].dup

      result = try_to_move_cat(stage, cat: 0, direction: direction)

      expected = {
        type: :cat_moved,
        cat: 0,
        from: original_position,
        to: { x: original_position[:x] + direction[:x], y: original_position[:y] + direction[:y] }
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
    original_position = stage[:cats][0].dup

    result = try_to_move_cat(stage, cat: 0, direction: { x: 0, y: 1 })

    expected = {
      type: :cat_bumped_into_wall,
      cat: 0,
      from: original_position,
      to: { x: original_position[:x], y: original_position[:y] + 1 }
    }
    assert.includes! result, expected
  end
end
