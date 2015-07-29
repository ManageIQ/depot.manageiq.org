class ExtractExtensionVersionLastCommitWorker
  include Sidekiq::Worker

  def perform(version_id)
    @version = ExtensionVersion.find(version_id)
    @extension = @version.extension

    if last_commit = @extension.octokit.commits(@extension.github_repo, ref: @version.version).first
      @version.update_attributes(
        last_commit_sha: last_commit[:sha],
        last_commit_at: last_commit[:commit][:author][:date],
        last_commit_string: last_commit[:commit][:message],
        last_commit_url: last_commit[:html_url]
      )
    end
  rescue Octokit::Conflict
    # Do nothing for empty repo
  end
end
