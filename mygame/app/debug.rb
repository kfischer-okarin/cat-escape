class Debug
  def initialize(args)
    @args = args
    @debug_mode = !$gtk.production
    @named_logs = {}
  end

  def toggle_debug_mode
    @debug_mode = !@debug_mode
  end

  def tick
    @named_logs.each_value do |message|
      log(message)
    end
    @named_logs.clear
  end

  def debug_mode?
    @debug_mode
  end

  def log(message)
    return unless @debug_mode

    @args.outputs.debug << message
  end

  def log_object(obj, except_vars: [])
    log "<#{obj.class}"
    obj.instance_variables.sort.each do |var|
      next if except_vars.include?(var)

      log "  #{var}: #{obj.instance_variable_get(var).inspect}"
    end
    log '>'
  end

  def named_log(name, value)
    @named_logs[name] = value
  end
end
