class SyncExtensionRepoWorker
  include Sidekiq::Worker

  def perform(extension_id, compatible_platforms = [])
    @extension = Extension.find(extension_id)
    `git clone #{@extension.github_url} #{@extension.repo_path}`

    tags = `cd #{@extension.repo_path} && git tag`.split("\n")

    SyncExtensionContentsAtVersionsWorker.perform_async(extension_id, ["master", *tags], compatible_platforms)
  end
end
