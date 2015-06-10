class EnsureGithubUserAndAccount
  def initialize(github_user)
    @github_user = github_user
  end

  def process!
    # NOTE: This is very similar to User.find_or_create_from_github_oauth,
    # except we're using the user object obtained from the GitHub API rather
    # than OAuth. Also, we must save the account without OAuth fields. We
    # ought to come back to this and DRY it up...

    account = Account.where(
      username: @github_user[:login],
      provider: "github"
    ).first_or_initialize

    if @github_user[:name].include?(" ")
      split = @github_user[:name].split(" ")
      first_name = split[0]
      last_name = split[1]
    else
      first_name = @github_user[:name]
      last_name = nil
    end

    account.user ||= User.new(
      first_name: first_name,
      last_name: last_name,
      email: @github_user[:email]
    )

    account.save(validate: false)
    account.user.save(validate: false)

    return account.user, account
  end
end

