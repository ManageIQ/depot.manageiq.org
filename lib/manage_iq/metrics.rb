module ManageIQ
  class Metrics
    def self.increment(stat)
      STATSD.increment(stat) if defined? STATSD
    end

    def self.get(key, per = "1day", from = "-2week")
      JSON.parse(
        Net::HTTP.get(
          GRAPHITE[:hostname],
          %[/render?target=hitcount(transformNull(stats.#{key}),"#{per}")&from=#{from}&format=json],
          GRAPHITE[:port]
        )
      )[0]["datapoints"].map { |n, t| n }
    rescue NoMethodError
      [0]
    end
  end
end
