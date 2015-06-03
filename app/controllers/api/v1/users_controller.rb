class Api::V1::UsersController < Api::V1Controller
  #
  # GET /api/v1/users/:user
  #
  # Return the specified user and their associated data. If the user does not
  # exist, return a 404.
  #
  # @example
  #   GET /api/v1/users/chef
  #
  def show
    @user = Account.for(
      'github'
    ).joins(:user).with_username(params[:user]).first!.user
    @github_usernames = @user.accounts.for('github').map(&:username).sort
    @followed_extensions = @user.followed_extensions.order('name ASC')
    @owned_tools = @user.tools.order('name ASC')
    @collaborated_tools = @user.collaborated_tools.order('name ASC')
  end
end
