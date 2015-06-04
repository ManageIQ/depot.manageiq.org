class Api::V1::ExtensionVersionsController < Api::V1Controller
  #
  # GET /api/v1/extensions/:extension/versions/:version
  #
  # Return a specific ExtensionVersion. Returns a 404 if the +Extension+ or
  # +ExtensionVersion+ does not exist.
  #
  # @example
  #   GET /api/v1/extensions/redis/versions/1.1.0
  #
  def show
    @extension = Extension.with_name(params[:extension]).first!
    @extension_version = @extension.get_version!(params[:version])
  end

  #
  # GET /api/v1/extensions/:extension/versions/:version/download
  #
  # Redirects the user to the extension artifact
  #
  def download
    @extension = Extension.with_name(params[:extension]).first!
    @extension_version = @extension.get_version!(params[:version])

    ExtensionVersion.increment_counter(:api_download_count, @extension_version.id)
    Extension.increment_counter(:api_download_count, @extension.id)
    ManageIQ::Metrics.increment('extension.downloads.api')

    redirect_to @extension_version.tarball.url
  end
end
