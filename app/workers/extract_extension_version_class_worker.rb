class ExtractExtensionVersionClassWorker
  include Sidekiq::Worker

  def perform(version_id, path)
    @version = ExtensionVersion.find(version_id)
    @extension = version.extension
    contents = @extension.octokit.contents(@extension.github_repo, ref: @version.version, path: path)

    @version.extension_version_content_items.create(
      name: contents[:name],
      path: contents[:path],
      item_type: "Class",
      github_url: contents[:github_url]
    )
  end
end
