class ExtractExtensionCollaboratorWorker
  include Sidekiq::Worker

  def perform(extension_id, github_login)
    @extension = Extension.find(extension_id)
    @collaborator = octokit.user(github_login)

    AddExtensionCollaborator.new(@extension, @collaborator).process!
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end
