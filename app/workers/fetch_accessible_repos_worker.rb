class FetchAccessibleReposWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    repos = []

    loop do
      r = user.octokit.repos(nil, per_page: 100)
      break if r.none?
      repos << r.map { |r| r.to_h.slice(:full_name, :name, :description) } rescue []
    end

    Rails.configuration.redis.setex("user-repos-#{user.id}", 5.minutes.to_i, Marshal.dump(repos))
  end
end
