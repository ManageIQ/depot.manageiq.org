class ExtractExtensionVersionsWorker
  include Sidekiq::Worker

  def perform(extension_id, compatible_platforms)
    extension = Extension.find(extension_id)

    octokit.tags(extension.github_repo).each do |tag|
      ExtractExtensionVersionWorker.perform_async(extension.id, tag[:name], compatible_platforms)
    end
  end

  private

  def octokit
    @octokit ||= Rails.configuration.octokit
  end
end
