require 'extension_upload'
require 'mixlib/authentication/signatureverification'

class Api::V1::ExtensionUploadsController < Api::V1Controller
  before_filter :require_upload_params, only: :create
  before_filter :authenticate_user!

  attr_reader :current_user

  #
  # POST /api/v1/extensions
  #
  # Accepts extensions to share. A sharing request is a multipart POST. Two of
  # those parts are relevant to this method: +extension+ and +tarball+.
  #
  # The +extension+ part is a serialized JSON object which can optionally contain a
  # +"category"+ key. The value of this key is the name of the category to
  # which this extension belongs.
  #
  # The +tarball+ part is a gzipped tarball containing the extension. Crucially,
  # this tarball must contain a +metadata.json+ entry, which is typically
  # generated by knife, and derived from the extension's +metadata.rb+.
  #
  # There are two use cases for sharing an extension: adding a new extension to
  # the community site, and updating an existing extension. Both are handled by
  # this action.
  #
  # There are also several failure modes for sharing an extension. These include,
  # but are not limited to, forgetting to upload a tarball, uploading a tarball
  # without a metadata.json entry, and so forth.
  #
  # The majority of the work happens between +ExtensionUpload+,
  # +ExtensionUpload::Parameters+, and +Extension+
  #
  # @see Extension
  # @see ExtensionUpload
  # @see ExtensionUpload::Parameters
  #
  def create
    extension_upload = ExtensionUpload.new(current_user, upload_params)

    begin
      authorize! extension_upload.extension
    rescue
      render_not_authorized([t('api.error_messages.unauthorized_upload_error')])
    else
      extension_upload.finish do |errors, extension, extension_version|
        if errors.any?
          error(
            error_code: t('api.error_codes.invalid_data'),
            error_messages: errors.full_messages
          )
        else
          @extension = extension

          ExtensionNotifyWorker.perform_async(extension_version.id)

          if ROLLOUT.active?(:fieri) && ENV['FIERI_URL'].present?
            FieriNotifyWorker.perform_async(
              extension_version.id
            )
          end

          ManageIQ::Metrics.increment 'extension.version.published'
          UniverseCache.flush

          render :create, status: 201
        end
      end
    end
  end

  #
  # DELETE /api/v1/extensions/:extension
  #
  # Destroys the specified extension. If it does not exist, return a 404.
  #
  # @example
  #   DELETE /api/v1/extensions/redis
  #
  def destroy
    @extension = Extension.with_name(params[:extension]).first!

    begin
      authorize! @extension
    rescue
      error({}, 403)
    else
      @latest_extension_version_url = api_v1_extension_version_url(
        @extension, @extension.latest_extension_version
      )

      @extension.destroy

      if @extension.destroyed?
        ExtensionDeletionWorker.perform_async(@extension.as_json)
        ManageIQ::Metrics.increment 'extension.deleted'
        UniverseCache.flush
      end
    end
  end

  rescue_from ActionController::ParameterMissing do |e|
    error(
      error_code: t('api.error_codes.invalid_data'),
      error_messages: [t("api.error_messages.missing_#{e.param}")]
    )
  end

  rescue_from Mixlib::Authentication::AuthenticationError do |_e|
    error(
      error_code: t('api.error_codes.authentication_failed'),
      error_messages: [t('api.error_messages.authentication_request_error')]
    )
  end

  #
  # DELETE /api/v1/extensions/:extension/versions/:version
  #
  # Destroys the specified extension version. If it does not exist, return a 404.
  #
  # @example
  #   DELETE /api/v1/extensions/redis/versions/1.0.0
  #
  def destroy_version
    @extension = Extension.with_name(params[:extension]).first!
    @extension_version = @extension.get_version!(params[:version])

    begin
      authorize! @extension, :destroy?
    rescue
      error({}, 403)
    else
      @extension_version.destroy
      UniverseCache.flush
    end
  end

  private

  #
  # The parameters required to upload an extension
  #
  # @raise [ActionController::ParameterMissing] if the +:extension+ parameter is
  #   missing
  # @raise [ActionController::ParameterMissing] if the +:tarball+ parameter is
  #   missing
  #
  def upload_params
    {
      extension: params.require(:extension),
      tarball: params.require(:tarball)
    }
  end

  alias_method :require_upload_params, :upload_params

  #
  # Finds a user specified in the request header or renders an error if
  # the user doesn't exist. Then attempts to authorize the signed request
  # against the users public key or renders an error if it fails.
  #
  def authenticate_user!
    username = request.headers['X-Ops-Userid']
    user = Account.for('chef_oauth2').where(username: username).first.try(:user)

    unless user
      return error(
        {
          error_code: t('api.error_codes.authentication_failed'),
          error_messages: [t('api.error_messages.invalid_username', username: username)]
        },
        401
      )
    end

    if user.public_key.nil?
      return error(
        {
          error_code: t('api.error_codes.authentication_failed'),
          error_messages: [t('api.error_messages.missing_public_key_error', current_host: request.base_url)]
        },
        401
      )
    end

    auth = Mixlib::Authentication::SignatureVerification.new.authenticate_user_request(
      request,
      OpenSSL::PKey::RSA.new(user.public_key)
    )

    if auth
      @current_user = user
    else
      error(
        {
          error_code: t('api.error_codes.authentication_failed'),
          error_messages: [t('api.error_messages.authentication_key_error')]
        },
        401
      )
    end
  end
end
