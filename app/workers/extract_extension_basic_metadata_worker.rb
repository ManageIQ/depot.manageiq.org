class ExtractExtensionBasicMetadata
  include Sidekiq::Worker

  def perform(extension_id)
    @extension = Extension.find(extension_id)
    repo = octokit.repo(@extension.github_repo)

    @extension.update_attributes(
      extension_followers_count: repo[:stargazers_count],
      issues_url: "https://github.com/#{@extension.github_repo}/issues"
    )
  end

  private

  def octokit
    @octokit ||= Rails.configuration.octokit
  end
end
