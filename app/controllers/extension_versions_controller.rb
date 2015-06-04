class ExtensionVersionsController < ApplicationController
  before_filter :set_extension_and_version

  #
  # GET /extensions/:extension_id/versions/:version/download
  #
  # Redirects the user to the extension artifact
  #
  def download
    ExtensionVersion.increment_counter(:web_download_count, @version.id)
    Extension.increment_counter(:web_download_count, @extension.id)
    ManageIQ::Metrics.increment('extension.downloads.web')

    redirect_to @version.tarball.url
  end

  #
  # GET /extensions/:extension_id/versions/:version
  #
  # Displays information about this particular extension version
  #
  def show
    @extension_versions = @extension.sorted_extension_versions
    @owner = @extension.owner
    @collaborators = @extension.collaborators
    @supported_platforms = @version.supported_platforms
    @owner_collaborator = Collaborator.new resourceable: @extension, user: @owner
  end

  private

  def set_extension_and_version
    @extension = Extension.with_name(params[:extension_id]).first!
    @version = @extension.get_version!(params[:version])
  end
end
