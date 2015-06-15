class CreateExtension
  def initialize(params, user, github)
    @params = params
    @tags = params[:tag_tokens]
    @compatible_platforms = params[:compatible_platforms]
    @user = user
    @github = github
  end

  def process!
    Extension.new(@params).tap do |extension|
      extension.owner = @user

      if extension.valid? and repo_valid?(extension)
        ActiveRecord::Base.transaction do
          extension.save
          create_tags(extension)
        end

        CollectExtensionMetadataWorker.perform_async(extension.id, @compatible_platforms.select { |p| !p.strip.blank? })
      end
    end
  end

  private

  def repo_valid?(extension)
    begin
      @github.access_token = user.github_account.oauth_token
      result = @github.collaborator?(extension.github_repo, @user.github_account.username)
    rescue ArgumentError, Octokit::Unauthorized, Octokit::Forbidden
      result = false
    end

    if !result then extension.errors[:github_url] = I18n.t("extension.github_url_format_error") end

    result
  end

  def create_tags(extension)
    (@tags || "").split(",").map(&:strip).uniq.each do |tag|
      extension.taggings.add(tag)
    end
  end
end
