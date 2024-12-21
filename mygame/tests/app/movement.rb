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

  it 'can push a box into an empty cell' do
    stage = prepare_stage(<<~STAGE)
      XXXXX
      XCB X
      XXXXX
    STAGE

    result = try_to_move_cat(stage, cat: 0, direction: { x: 1, y: 0 })

    expected1 = {
      type: :cat_moved,
      cat: 0,
      from: { x: 1, y: 1 },
      to: { x: 2, y: 1 }
    }
    assert.includes! result, expected1
    expected2 = {
      type: :box_moved,
      from: { x: 2, y: 1 },
      to: { x: 3, y: 1 }
    }
    assert.includes! result, expected2
  end

  it 'cannot push a box into a wall' do
    stage = prepare_stage(<<~STAGE)
      XXXX
      XCBX
      XXXX
    STAGE

    result = try_to_move_cat(stage, cat: 0, direction: { x: 1, y: 0 })

    expected = {
      type: :cat_bumped_into_box,
      cat: 0,
      from: { x: 1, y: 1 },
      to: { x: 2, y: 1 }
    }
    assert.includes! result, expected
    event_types = result.map { |event| event[:type] }
    assert.includes_no! event_types, :box_moved
    assert.includes_no! event_types, :cat_moved
  end

  it 'cannot push a box into another box' do
    stage = prepare_stage(<<~STAGE)
      XXXXX
      XCBBX
      XXXXX
    STAGE

    result = try_to_move_cat(stage, cat: 0, direction: { x: 1, y: 0 })

    expected = {
      type: :cat_bumped_into_box,
      cat: 0,
      from: { x: 1, y: 1 },
      to: { x: 2, y: 1 }
    }
    assert.includes! result, expected
    event_types = result.map { |event| event[:type] }
    assert.includes_no! event_types, :box_moved
    assert.includes_no! event_types, :cat_moved
  end

  it 'cannot push a box into a cat' do
    stage = prepare_stage(<<~STAGE)
      XXXXX
      XCBCX
      XXXXX
    STAGE

    result = try_to_move_cat(stage, cat: 0, direction: { x: 1, y: 0 })

    expected = {
      type: :pushed_box_into_cat,
      from_cat: 0,
      to_cat: 1,
      from: { x: 2, y: 1 },
      to: { x: 3, y: 1 }
    }
    assert.includes! result, expected
    event_types = result.map { |event| event[:type] }
    assert.includes_no! event_types, :box_moved
    assert.includes_no! event_types, :cat_moved
  end
end
