class CreateExtension
  def initialize(params, user)
    @params = params
    @tags = params[:tag_tokens]
    @compatible_platforms = params[:compatible_platforms] || []
    @user = user
    @github = @user.octokit
  end

  def process!
    Extension.new(@params).tap do |extension|
      extension.owner = @user

      if extension.valid? and repo_valid?(extension)
        repo_info = @github.repo(extension.github_repo)

        if org = repo_info[:organization]
          extension.github_organization = GithubOrganization.where(github_id: org[:id]).first_or_create!(
            name: org[:login],
            avatar_url: org[:avatar_url]
          )
          extension.owner_name = org[:login]
        else
          extension.owner_name = extension.owner.username
        end

        extension.save

        CollectExtensionMetadataWorker.perform_async(extension.id, @compatible_platforms.select { |p| !p.strip.blank? })
        SetupExtensionWebHooksWorker.perform_async(extension.id)
        NotifyModeratorsOfNewExtensionWorker.perform_async(extension.id)
      elsif existing = Extension.unscoped.where(enabled: false, github_url: extension.github_url).first
        existing.update_attribute(:enabled, true)
        return existing
      end
    end
  end

  private

  def repo_valid?(extension)
    begin
      result = @github.collaborator?(extension.github_repo, @user.github_account.username)
    rescue ArgumentError, Octokit::Unauthorized, Octokit::Forbidden
      result = false
    end

    if !result then extension.errors[:github_url] = I18n.t("extension.github_url_format_error") end

    result
  end
end
