class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:create]

  #
  # GET /sign-in
  #
  # Redirects the user to the OmniAuth path for authentication
  #
  def new
    redirect_to '/auth/chef_oauth2'
  end

  #
  # POST /auth/chef_oauth2/callback
  #
  # Creates a new session for the user from the OmniAuth Auth hash.
  #
  def create
    user = User.find_or_create_from_chef_oauth(request.env['omniauth.auth'])
    session[:user_id] = user.id
    redirect_to redirect_path, notice: t('user.signed_in', name: user.name)
  end

  #
  # DELETE /sign-out
  #
  # Signs out the user
  #
  def destroy
    reset_session

    flash[:signout] = true

    redirect_to root_path, notice: t('user.signed_out')
  end

  private

  def redirect_path
    stored_location || root_path
  end
end
