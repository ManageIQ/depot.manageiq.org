class SyncExtensionRepoWorker
  include Sidekiq::Worker

  def perform(extension_id, compatible_platforms = [])
    @extension = Extension.find(extension_id)
    `git clone #{@extension.github_url} #{@extension.repo_path}`

    `cd #{@extension.repo_path} && git pull`
    tags = @extension.octokit.releases(@extension.github_repo).map { |r| r[:tag_name] }
    @extension.extension_versions.where.not(version: tags).destroy_all

    SyncExtensionContentsAtVersionsWorker.perform_async(extension_id, ["master", *tags], compatible_platforms)
  end
end
