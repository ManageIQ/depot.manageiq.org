class ExtensionsController < ApplicationController
  before_filter :assign_extension, except: [:index, :directory, :new, :create]
  before_filter :store_location_then_authenticate_user!, only: [:follow, :unfollow, :adoption]
  before_filter :authenticate_user!, only: [:new, :create]

  skip_before_action :verify_authenticity_token, only: [:webhook]

  #
  # GET /extensions
  #
  # Return all extensions. Extensions are sorted alphabetically by name.
  # Optionally a category can be specified to return only extensions for a
  # given category. Extensions can also be returned as an atom feed if the atom
  # format is specified.
  #
  # @example
  #   GET /extensions?q=redis
  #
  # Pass in order params to specify a sort order.
  #
  # @example
  #   GET /extensions?order=recently_updated
  #
  def index
    @extensions = Extension.includes(:extension_versions)

    if params[:q].present?
      @extensions = @extensions.search(params[:q])
    end

    if params[:featured].present?
      @extensions = @extensions.featured
    end

    if params[:order].present?
      @extensions = @extensions.ordered_by(params[:order])
    end

    if params[:order].blank? && params[:q].blank?
      @extensions = @extensions.order(:name)
    end

    if params[:supported_platforms].present?
      @extensions = @extensions.supported_platforms(params[:supported_platforms])
    end

    @number_of_extensions = @extensions.count(:all)
    @extensions = @extensions.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.atom
    end
  end

  #
  # GET /extensions/new
  #
  # Show a form for creating a new extension.
  #
  def new
    if @repo_names = Rails.configuration.redis.get("user-repos-#{current_user.id}")
      @repo_names = Marshal.load(@repo_names)
    else
      FetchAccessibleReposWorker.perform_async(current_user.id)
    end

    @extension = Extension.new
  end

  #
  # POST /extensions
  #
  # Create an extension.
  #
  def create
    eparams = params.require(:extension).permit(:name, :description, :github_url, :tag_tokens, compatible_platforms: [])
    create_extension = CreateExtension.new(eparams, current_user)
    @extension = create_extension.process!

    if @extension.errors.none?
      redirect_to extension_path(@extension), notice: t("extension.created")
    else
      @repo_names = current_user.octokit.repos.map { |r| r.to_h.slice(:full_name, :name, :description) } rescue []
      render :new
    end
  end

  #
  # GET /extensions/directory
  #
  # Return the three most recently updated and created extensions.
  #
  def directory
    @recently_updated_extensions = Extension.
      includes(:extension_versions).
      ordered_by('recently_updated').
      limit(5)
    @most_downloaded_extensions = Extension.
      includes(:extension_versions).
      ordered_by('most_downloaded').
      limit(5)
    @most_followed_extensions = Extension.
      includes(:extension_versions).
      ordered_by('most_followed').
      limit(5)
    @featured_extensions = Extension.
      includes(:extension_versions).
      featured.
      order(:name).
      limit(5)

    @extension_count = Extension.count
    @user_count = User.count
  end

  #
  # GET /extensions/:id
  #
  # Displays an extension.
  #
  def show
    @latest_version = @extension.latest_extension_version
    @extension_versions = @extension.sorted_extension_versions
    @collaborators = @extension.collaborators
    @supported_platforms = @extension.supported_platforms
    @downloads = DailyMetric.counts_since(@latest_version.download_daily_metric_key, Date.today - 1.month) if @latest_version
    @commits = DailyMetric.counts_since(@extension.commit_daily_metric_key, Date.today - 1.year)

    respond_to do |format|
      format.atom
      format.html
    end
  end

  #
  # GET /extensions/:id/download
  #
  # Redirects to the download location for the latest version of this extension.
  #
  def download
    extension = Extension.with_name(params[:id]).first!
    latest_version = extension.latest_extension_version
    ManageIQ::Metrics.increment('extension.downloads.web')
    DailyMetric.increment(latest_version.download_daily_metric_key)
    redirect_to extension_version_download_url(extension, latest_version)
  end

  #
  # PATCH /extensions/:id
  #
  # Update a the specified extension. This currently only supports updating the
  # extension's URLs. It also only returns JSON.
  #
  # NOTE: :id must be the name of the extension.
  #
  def update
    authorize! @extension, :manage?

    @extension.update_attributes(extension_edit_params)

    key = if extension_edit_params.key?(:up_for_adoption)
            if extension_edit_params[:up_for_adoption] == 'true'
              'adoption.up'
            else
              'adoption.down'
            end
          else
            'extension.updated'
          end

    redirect_to @extension, notice: t(key, name: @extension.name)
  end

  #
  # PUT /extensions/:extension/follow
  #
  # Makes the current user follow the specified extension.
  #
  def follow
    FollowExtensionWorker.perform_async(@extension.id, current_user.id)
    @extension.extension_followers.create(user: current_user)
    ManageIQ::Metrics.increment 'extension.followed'

    render_follow_button
  end

  #
  # DELETE /extensions/:extension/unfollow
  #
  # Makes the current user unfollow the specified extension.
  #
  def unfollow
    UnfollowExtensionWorker.perform_async(@extension.id, current_user.id)
    extension_follower = @extension.extension_followers.
      where(user: current_user).first!
    extension_follower.destroy
    ManageIQ::Metrics.increment 'extension.unfollowed'

    render_follow_button
  end

  #
  # PUT /extensions/:extension/deprecate
  #
  # Deprecates the extension, sets the replacement extension, kicks off a notifier
  # to send emails and redirects back to the deprecated extension.
  #
  def deprecate
    authorize! @extension

    replacement_extension = Extension.with_name(
      extension_deprecation_params[:replacement]
    ).first!

    if @extension.deprecate(replacement_extension)
      ExtensionDeprecatedNotifier.perform_async(@extension.id)

      redirect_to(
        @extension,
        notice: t(
          'extension.deprecated',
          extension: @extension.name,
          replacement_extension: replacement_extension.name
        )
      )
    else
      redirect_to @extension, notice: @extension.errors.full_messages.join(', ')
    end
  end

  #
  # DELETE /extensions/:extension/deprecate
  #
  # Un-deprecates the extension and sets its replacement extension to nil.
  #
  def undeprecate
    authorize! @extension

    @extension.update_attributes(deprecated: false, replacement: nil)

    redirect_to(
      @extension,
      notice: t(
        'extension.undeprecated',
        extension: @extension.name
      )
    )
  end

  #
  # POST /extensions/:id/adoption
  #
  # Sends an email to the extension owner letting them know that someone is
  # interested in adopting their extension.
  #
  def adoption
    AdoptionMailer.delay.interest_email(@extension, current_user)

    redirect_to(
      @extension,
      notice: t(
        'adoption.email_sent',
        extension_or_tool: @extension.name
      )
    )
  end

  #
  # PUT /extensions/:extension/toggle_featured
  #
  # Allows a Supermarket admin to set an extension as featured or
  # unfeatured (if it is already featured).
  #
  def toggle_featured
    authorize! @extension

    @extension.update_attribute(:featured, !@extension.featured)

    redirect_to(
      @extension,
      notice: t(
        'extension.featured',
        extension: @extension.name,
        state: "#{@extension.featured? ? 'featured' : 'unfeatured'}"
      )
    )
  end

  #
  # PUT /extensions/:extension/disable
  #
  # Allows an admin to disable an extension, hiding it from view.
  #
  def disable
    authorize! @extension
    @extension.update_attribute(:enabled, false)
    redirect_to "/", notice: t("extension.disabled", extension: @extension.name)
  end

  #
  # PUT /extensions/:extension/enable
  #
  # Allows an admin to enable an extension, hiding it from view.
  #
  def enable
    authorize! @extension, :disable?
    @extension.update_attribute(:enabled, true)
    redirect_to extension_url(@extension), notice: t("extension.enabled", extension: @extension.name)
  end

  #
  # PUT /extensions/:extension/report
  #
  # Notifies moderators to check an extension for inappropriate content.
  #
  def report
    NotifyModeratorsOfReportedExtensionWorker.perform_async(@extension.id, params[:report][:description])
    redirect_to @extension, notice: t("extension.reported", extension: @extension.name)
  end

  #
  # GET /extensions/:id/deprecate_search?q=QUERY
  #
  # Return extensions with a name that contains the specified query. Takes the
  # +q+ parameter for the query. Only returns extension elgible for replacement -
  # extensions that are not deprecated and not the extension being deprecated.
  #
  # @example
  #   GET /extensions/redis/deprecate_search?q=redisio
  #
  def deprecate_search
    @results = @extension.deprecate_search(params.fetch(:q, nil))

    respond_to do |format|
      format.json
    end
  end

  #
  # POST /extensions/:id/webhook
  #
  # Receive updates from GitHub's webhook API about an extension's repo.
  #
  def webhook
    # TODO: Don't do a full update on watch event
    CollectExtensionMetadataWorker.perform_async(@extension.id, [])
    head :ok
  end

  private

  def assign_extension
    @extension ||= begin
      Extension.with_name(params[:id]).first!
    rescue ActiveRecord::RecordNotFound
      if extension = Extension.unscoped.with_name(params[:id]).first
        if current_user == extension.owner or (current_user and current_user.roles_mask > 0)
          @extension = extension
        else
          raise ActiveRecord::RecordNotFound
        end
      end
    end
  end

  def store_location_then_authenticate_user!
    store_location!(extension_path(@extension))
    authenticate_user!
  end

  def extension_edit_params
    params.require(:extension).permit(:source_url, :issues_url, :up_for_adoption, :tag_tokens, :name, :description)
  end

  def extension_deprecation_params
    params.require(:extension).permit(:replacement)
  end

  def render_follow_button
    # In order to refresh the follower count the extension must be
    # reloaded before rendering.
    @extension.reload

    if params[:list].present?
      render partial: 'follow_button_list', locals: { extension: @extension }
    else
      render partial: 'follow_button_show', locals: { extension: @extension }
    end
  end
end
