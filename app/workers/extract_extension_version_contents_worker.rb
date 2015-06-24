class ExtractExtensionVersionContentsWorker
  include Sidekiq::Worker

  def perform(version_id, path = "")
    @version = ExtensionVersion.find(version_id)
    @extension = @version.extension
    contents = @extension.octokit.contents(@extension.github_repo, ref: @version.version, path: path)

    contents.each do |item|
      if item[:type] == "file" and item.name =~ /(\.yml|\.yaml)$/
        ExtractExtensionVersionFileWorker.perform_async(version_id, item[:path])
      elsif item[:type] == "dir" and item.name =~ /\.class$/
        ExtractExtensionVersionClassWorker.perform_async(version_id, item[:path])
      elsif item[:type] == "dir"
        ExtractExtensionVersionContentsWorker.perform_async(version_id, item[:path])
      end
    end
  end
end
