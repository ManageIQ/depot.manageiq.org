class ExtractExtensionStargazerWorker
  include Sidekiq::Worker

  def perform(extension_id, github_login)
    @extension = Extension.find(extension_id)
    @stargazer = @extension.octokit.user(github_login)

    ActiveRecord::Base.transaction do
      user, account = EnsureGithubUserAndAccount.new(@stargazer).process!
      @extension.extension_followers.create(user: user)
    end
  end
end
