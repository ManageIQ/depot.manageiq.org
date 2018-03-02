def Object.const_missing(const)
  if const == :ROLLOUT
    require 'redis'

    redis_connect = {}.tap { |h| h[:host] = ENV["REDIS_HOST"] if ENV["REDIS_HOST"] }
    redis = Redis.new(redis_connect)

    Object.const_set('ROLLOUT', Rollout.new(redis))

    features = ENV['FEATURES'].to_s.split(',')

    #
    # Features that are defined in rollout but are no longer defined
    # in ENV['FEATURES'] need to be deactivated.
    #
    (ROLLOUT.features - features).each do |feature|
      ROLLOUT.deactivate(feature)
    end

    #
    # Features that are defined in ENV['FEATURES'] but are
    # not defined in rollout need to be activated.
    #
    (features - ROLLOUT.features).each do |feature|
      ROLLOUT.activate(feature)
    end

    ROLLOUT
  else
    super
  end
end
