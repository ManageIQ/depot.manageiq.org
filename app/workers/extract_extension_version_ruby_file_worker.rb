class ExtractExtensionVersionRubyFileWorker
  include Sidekiq::Worker

  def perform(version_id, path)
    @version = ExtensionVersion.find(version_id)
    @extension = @version.extension
    contents = @extension.octokit.contents(@extension.github_repo, ref: @version.version, path: path)
    body = Base64.decode64(contents[:content])

    ExtensionVersion
      .where(id: version_id)
      .update_all(["rb_line_count = rb_line_count + ?", body.count("\n") + 1])
  end
end
