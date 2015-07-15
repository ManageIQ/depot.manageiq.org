class UsersController < ApplicationController
  before_filter :assign_user

  #
  # GET /users/:id
  #
  # Display a user and a users extensions for a given context. The extensions
  # context is given via the tab paramter. Contexts include extensions the user
  # collaborates on, extensions the user follows and the default context of extensions
  # the user owns.
  #
  def show
    if @user == current_user
      @extensions = Extension.unscoped
    else
      @extensions = Extension.all
    end

    case params[:tab]
    when 'collaborates'
      @extensions = @extensions.merge(@user.collaborated_extensions)
    when 'follows'
      @extensions = @extensions.merge(@user.followed_extensions)
    else
      @extensions = @extensions.merge(@user.owned_extensions)
    end

    @extensions = @extensions.order(:name).page(params[:page]).per(20)
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
