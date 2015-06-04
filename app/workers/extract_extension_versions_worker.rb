class ExtractExtensionVersionsWorker
  include Sidekiq::Worker

  def perform(extension_id)
    extension = Extension.find(extension_id)

    octokit.tags(extension.github_repo).each do |tag|
      ExtractExtensionVersionWorker.process_async(extension.id, tag[:name])
    end
  end

  private

  def octokit
    @octokit ||= Rails.configuration.octokit
  end
end
