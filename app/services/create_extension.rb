class CreateExtension
  def initialize(params, user, github)
    @params = params
    @user = user
    @github = github
  end

  def process!
    Extension.new(@params).tap do |extension|
      if extension.valid? and repo_valid?(extension)
        extension.save
        CollectExtensionMetadataWorker.perform_async(extension.id)
      end
    end
  end

  private

  def repo_valid?(extension)
    begin
      result = @github.collaborator?(extension.github_repo, @user.github_account.username)
    rescue ArgumentError
      result = false
    end

    if !result then extension.errors[:github_url] = I18n.t("extension.github_url_format_error") end

    result
  end
end
