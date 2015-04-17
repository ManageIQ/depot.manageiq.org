def Object.const_missing(const)
  if const == :ROLLOUT
    require 'redis'

    redis_connect = {
      # url: ENV['REDIS_URL'] || 'redis://localhost:6379/0/supermarket',
      host: ENV['OPENSHIFT_REDIS_HOST'] || 'localhost',
      port: ENV['OPENSHIFT_REDIS_PORT'],
      db: 0
    }
    unless ENV['REDIS_PASSWORD'].blank?
      redis_connect[:password] = ENV['REDIS_PASSWORD']
    end

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
