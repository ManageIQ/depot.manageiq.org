class UsersController < ApplicationController
  before_filter :assign_user, except: :accessible_repos

  #
  # GET /users/:id
  #
  # Display a user and a users extensions for a given context. The extensions
  # context is given via the tab paramter. Contexts include extensions the user
  # collaborates on, extensions the user follows and the default context of extensions
  # the user owns.
  #
  def show
    case params[:tab]
    when 'collaborates'
      @extensions = @user.collaborated_extensions
    when 'follows'
      @extensions = @user.followed_extensions
    else
      @extensions = @user.owned_extensions
    end

    @extensions = @extensions.unscope(where: :enabled) if @user == current_user
    @extensions = @extensions.order(:name).page(params[:page]).per(20)
  end

  def accessible_repos
    if @repo_names = Rails.configuration.redis.get("user-repos-#{current_user.id}")
      @repo_names = Marshal.load(@repo_names)
      render json: { repo_names: @repo_names }
    else
      render json: { waiting: true }
    end
  end

  #
  # GET /users/:id/followed_extension_activity
  #
  # Displays a feed of extension activity for the
  # extensions the specified user follows.
  #
  def followed_extension_activity
    @followed_extension_activity = @user.followed_extension_versions.limit(50)
  end

  #
  # PUT /users/:id/make_admin
  #
  # Assigns the admin role to a given user then redirects back to
  # the users profile.
  #
  def make_admin
    authorize! @user
    @user.roles = @user.roles + ['admin']
    @user.save
    redirect_to @user, notice: t('user.made_admin', name: @user.username)
  end

  #
  # PUT /users/:id/disable
  #
  # Disables the given user then redirects back to home.
  #
  def disable(*args)
    authorize! @user
    @user.enabled = false
    @user.save
    @user.owned_extensions.update_all(enabled: false)
    redirect_to root_path, notice: t("user.disabled", name: @user.username)
  end

  #
  # DELETE /users/:id/revoke_admin
  #
  # Revokes the admin role to a given user then redirects back to
  # the users profile.
  #
  def revoke_admin
    authorize! @user
    @user.roles = @user.roles - ['admin']
    @user.save
    redirect_to @user, notice: t('user.revoked_admin', name: @user.username)
  end

  private

  def assign_user
    @user = Account.for('github').joins(:user).with_username(params[:id]).first!.user
  end
end
