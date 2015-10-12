class SetupExtensionWebHooksWorker
  include Sidekiq::Worker

  def perform(extension_id)
    @extension = Extension.find(extension_id)
    @octokit = @extension.octokit

    begin
      @octokit.create_hook(
        @extension.github_repo, "web",
        {
          url: Rails.application.routes.url_helpers.webhook_extension_url(@extension, username: @extension.owner_name),
          content_type: "json"
        },
        {
          events: ["release", "watch"],
          active: true
        }
      )
    rescue Octokit::UnprocessableEntity
      # Do nothing and continue if the hook already exists
    end
  end
end
