module Animation
  class << self
    def build(values)
      values.merge(ticks: 0, finished: false)
    end
  end
end
