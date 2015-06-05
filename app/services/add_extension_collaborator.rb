class AddExtensionCollaborator
  def initialize(extension, github_user)
    @extension = extension
    @github_user = github_user
  end

  def process!
    ActiveRecord::Base.transaction do
      user, account = EnsureGithubUserAndAccount.new(@github_user).process!
      Collaborator.create(user: user, resourceable: @extension)
    end
  end
end
