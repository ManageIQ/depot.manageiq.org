module ManageIQ
  class Metrics
    def self.increment(stat)
      STATSD.increment(stat) if defined? STATSD
    end
  end
end
