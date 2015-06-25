class ExtractExtensionVersionClassWorker
  include Sidekiq::Worker

  def perform(version_id, path)
    @version = ExtensionVersion.find(version_id)
    @extension = @version.extension
    contents = @extension.octokit.contents(@extension.github_repo, ref: @version.version, path: path)

    @version.extension_version_content_items.create(
      name: path.gsub(/.+\//, ""),
      path: path,
      item_type: "Class",
      github_url: "https://github.com/#{@extension.github_repo}/blob/#{@version.version}/" + path
    )
  end
end
