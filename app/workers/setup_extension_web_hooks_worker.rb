class SetupExtensionWebHooksWorker
  include Sidekiq::Worker

  def perform(extension_id)
    @extension = Extension.find(extension_id)
    @octokit = @extension.octokit

    @octokit.create_hook(
      @extension.github_repo, "web",
      {
        url: Rails.application.routes.url_helpers.webhook_extension_url(@extension),
        content_type: "json"
      },
      {
        events: ["release", "watch"],
        active: true
      }
    )
  end
end
