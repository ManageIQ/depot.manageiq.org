require 'and_feathers'
require 'and_feathers/gzipped_tarball'
require 'tempfile'
require 'mixlib/authentication/signedheaderauth'

module ApiSpecHelpers
  #
  # Shares an extension with a given name and options using the /api/v1/extensions API.
  #
  # @param extension_name [String] the name of the extension to be shared
  # @param user [User] the user that's sharing the extension
  # @param opts [Hash] options that determine the contents of the tarball, signed header and request payload
  #
  # @option opts [Hash] :custom_metadata Custom values/attributes for the extension metadata
  # @option opts [Boolean] :with_invalid_public_key Make request with an invalid public key
  # @option opts [Array] :omitted_headers Any headers to omit from the signed request
  # @option opts [String] :category The category to share the extension to
  # @option opts [String] :payload a JSON representation of the request body
  #
  def share_extension(extension_name, user, opts = {})
    extensions_path = '/api/v1/extensions'
    extension_params = {}

    tarball = extension_upload(extension_name, opts)
    private_key = private_key(opts.fetch(:with_invalid_private_key, false))

    header = Mixlib::Authentication::SignedHeaderAuth.signing_object(
      http_method: 'post',
      path: extensions_path,
      user_id: user.username,
      timestamp: Time.now.utc.iso8601,
      body: tarball.read
    ).sign(private_key)

    opts.fetch(:omitted_headers, []).each { |h| header.delete(h) }

    category = opts.fetch(:category, 'other')

    unless category.nil?
      new_category = create(:category, name: category.titleize)
      extension_params[:category] = new_category.name
    end

    payload = opts.fetch(:payload, extension: JSON.generate(extension_params), tarball: tarball)

    post extensions_path, payload, header
  end

  #
  # Unshares an extension with a given name using the /api/v1/extensions/:extension API.
  #
  # @param extension_name [String] the name of the extension to be unshared
  # @param user [User] the user that's unsharing the extension
  #
  def unshare_extension(extension_name, user)
    extension_path = "/api/v1/extensions/#{extension_name}"

    header = Mixlib::Authentication::SignedHeaderAuth.signing_object(
      http_method: 'delete',
      path: extension_path,
      user_id: user.username,
      timestamp: Time.now.utc.iso8601,
      body: ''
    ).sign(private_key)

    delete extension_path, {}, header
  end

  #
  # Unshares an extension version with a given name using the /api/v1/extensions/:extension/versions/:version API.
  #
  # @param extension_name [String] the name of the extension version to be unshared
  # @param extension_version [String] the version of the extension to be unshared
  # @param user [User] the user that's unsharing the extension version
  #
  def unshare_extension_version(extension_name, version, user)
    extension_version_path = "/api/v1/extensions/#{extension_name}/versions/#{version}"

    header = Mixlib::Authentication::SignedHeaderAuth.signing_object(
      http_method: 'delete',
      path: extension_version_path,
      user_id: user.username,
      timestamp: Time.now.utc.iso8601,
      body: ''
    ).sign(private_key)

    delete extension_version_path, {}, header
  end

  def json_body
    JSON.parse(response.body)
  end

  def signature(resource)
    resource.except('created_at', 'updated_at', 'file', 'tarball_file_size')
  end

  def error_404
    {
      'error_messages' => [I18n.t('api.error_messages.not_found')],
      'error_code' => I18n.t('api.error_codes.not_found')
    }
  end

  def publish_version(extension, version)
    create(
      :extension_version,
      extension: extension,
      version: version
    )
  end

  private

  def private_key(invalid = false)
    key_name = invalid ? 'invalid_private_key.pem' : 'valid_private_key.pem'

    OpenSSL::PKey::RSA.new(
      File.read("spec/support/key_fixtures/#{key_name}")
    )
  end

  def extension_upload(extension_name, opts = {})
    begin
      if extension_name.ends_with?('.tgz')
        tarball = File.new("#{Rails.root}/spec/support/extension_fixtures/#{extension_name}")
      else
        custom_metadata = opts.fetch(:custom_metadata, {})

        metadata = {
          name: extension_name,
          version: '1.0.0',
          description: "Installs/Configures #{extension_name}",
          license: 'MIT',
          platforms: {
            'ubuntu' => '>= 12.0.0'
          },
          dependencies: {
            'apt' => '~> 1.0.0'
          }
        }.merge(custom_metadata)

        tarball = Tempfile.new([extension_name, '.tgz'], 'tmp').tap do |file|
          io = AndFeathers.build(extension_name) do |base_dir|
            base_dir.file('README.md') { '# README' }
            base_dir.file('metadata.json') do
              JSON.dump(metadata)
            end
          end.to_io(AndFeathers::GzippedTarball)

          file.write(io.read)
          file.rewind
        end
      end

      content_type = opts.fetch(:content_type, 'application/x-gzip')
      fixture_file_upload(tarball.path, content_type)
    ensure
      tarball.close
    end
  end
end
