class ExtractExtensionStargazersWorker
  include Sidekiq::Worker

  def perform(extension_id, page = 1)
    @extension = Extension.find(extension_id)
    @stargazers = @extension.octokit.stargazers(@extension.github_repo, page: page, per_page: 100)

    process_stargazers

    self.class.perform_async(extension_id, page + 1) if @stargazers.any?
  end

  private

  def process_stargazers
    @stargazers.each do |s|
      ExtractExtensionStargazerWorker.perform_async(@extension.id, s[:login])
    end
  end
end
