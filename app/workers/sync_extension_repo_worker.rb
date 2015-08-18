class SyncExtensionRepoWorker
  include Sidekiq::Worker

  def perform(extension_id, compatible_platforms = [])
    @extension = Extension.find(extension_id)

    clone_repo
    @tags = extract_tags_from_releases
    destroy_unreleased_versions

    SyncExtensionContentsAtVersionsWorker.perform_async(extension_id, @tags, compatible_platforms)
  end

  private

  def clone_repo
    `git clone #{@extension.github_url} #{@extension.repo_path}`
  end

  def extract_tags_from_releases
    tags = @extension.octokit.releases(@extension.github_repo).map { |r| r[:tag_name] }
    ["master", *tags]
  end

  def destroy_unreleased_versions
    @extension.extension_versions.where.not(version: @tags).destroy_all
  end
end
