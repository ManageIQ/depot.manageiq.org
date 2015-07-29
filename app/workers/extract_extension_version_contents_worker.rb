class ExtractExtensionVersionContentsWorker
  include Sidekiq::Worker

  def perform(version_id, path = "")
    @version = ExtensionVersion.find(version_id)
    @extension = @version.extension
    @version.extension_version_content_items.destroy_all if path == ""

    contents = @extension.octokit.contents(@extension.github_repo, ref: @version.version, path: path)

    contents.each do |item|
      if item[:type] == "file" and item.name =~ /(\.yml|\.yaml)$/
        ExtractExtensionVersionFileWorker.perform_async(version_id, item[:path])
      elsif item[:type] == "file" and item.name =~ /\.rb$/
        ExtractExtensionVersionRubyFileWorker.perform_async(version_id, item[:path])
      elsif item[:type] == "dir" and item.name =~ /\.class$/
        ExtractExtensionVersionClassWorker.perform_async(version_id, item[:path])
        ExtractExtensionVersionContentsWorker.perform_async(version_id, item[:path])
      elsif item[:type] == "dir"
        ExtractExtensionVersionContentsWorker.perform_async(version_id, item[:path])
      end
    end
  rescue Octokit::NotFound
    # Do nothing if the extension is no longer accessible
  end
end
