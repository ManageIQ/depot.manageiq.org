class SyncExtensionRepoWorker
  include Sidekiq::Worker

  def perform(extension_id)
    @extension = Extension.find(extension_id)
    `git clone #{@extension.github_url} #{@extension.repo_path}`

    tags = `cd #{@extension.repo_path} && git tag`.split("\n")

    SyncExtensionContentsAtVersions.perform_async(extension_id, ["master", *tags])
  end
end
