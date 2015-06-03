class PagesController < ApplicationController
  before_filter :authenticate_user!, only: :dashboard
  layout false, only: [:robots]

  #
  # GET /
  #
  # The first page a non-authenticated user sees. The welcome page gives the
  # user a taste of what Supermarket is all about.
  #
  def welcome
    redirect_to dashboard_path if current_user.present?

    @extension_count = Extension.count
    @user_count = User.count
  end

  #
  # GET /dashboard
  #
  # The dashboard for authenticated users. This displays the user's extensions,
  # collaborated extensions and new versions of extensions that the user follows.
  #
  def dashboard
    @extensions = current_user.owned_extensions.limit(5)
    @collaborated_extensions = current_user.collaborated_extensions.limit(5)
    @tools = current_user.tools.limit(5)
    @followed_extension_activity = current_user.followed_extension_versions.limit(50)
  end

  #
  # GET /robots.txt
  #
  # Instead of serving robots.txt out of the public directory, we serve it here
  # so that it can be populated with the correct host name.
  #
  def robots
    respond_to :text
  end
end
