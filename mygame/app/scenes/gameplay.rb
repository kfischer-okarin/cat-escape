module Scenes
  class Gameplay
    def initialize(args, stage_number:)
      args.state.stage_number = stage_number
      args.state.stage = prepare_stage(STAGES[stage_number])
      args.state.current_cat = 0
      args.audio[:bgm] = { input: 'audio/Wholesome.ogg', looping: true, gain: 0.3 }
      args.state.game_over = false
    end

    def tick(args)
      input_event = process_input(args) unless args.state.game_over

      gameplay_tick(args, input_event: input_event)

      game_over_screen(args) if args.state.game_over
    end
  end
end
