if ENV["STATSD_HOST"].present? && ENV["STATSD_PORT"].present?
  STATSD = Statsd.new ENV["STATSD_HOST"], ENV["STATSD_PORT"]
end

if ENV["GRAPHITE_HOST"].present? && ENV["GRAPHITE_PORT"].present?
  GRAPHITE = { hostname: ENV["GRAPHITE_HOST"], port: ENV["GRAPHITE_PORT"] }
end
