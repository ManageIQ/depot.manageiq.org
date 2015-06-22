class ExtractExtensionBasicMetadataWorker
  include Sidekiq::Worker

  def perform(extension_id)
    @extension = Extension.find(extension_id)
    repo = octokit.repo(@extension.github_repo)

    Extension.where(id: @extension.id).update_all(
      extension_followers_count: repo[:stargazers_count],
      issues_url: "https://github.com/#{@extension.github_repo}/issues"
    )
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end
