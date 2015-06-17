class ExtractExtensionBasicMetadataWorker
  include Sidekiq::Worker

  def perform(extension_id)
    @extension = Extension.find(extension_id)
    repo = octokit.repo(@extension.github_repo)

    @extension.assign_attributes(
      extension_followers_count: repo[:stargazers_count],
      issues_url: "https://github.com/#{@extension.github_repo}/issues"
    )
    puts @extension.save!(validate: false).inspect
    puts @extension.inspect
    puts @extension.errors.inspect
    puts Extension.find(extension_id).inspect
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end
