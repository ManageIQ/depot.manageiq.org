require 'net/http'
require 'uri'

class FieriNotifyWorker
  include Sidekiq::Worker
  include Rails.application.routes.url_helpers

  #
  # Send a POST request to the configured +FIERI_URL+ when a Extension Version
  # is shared.
  #
  # @param [Integer] extension_version_id the id for the Extension
  #
  # @return [Boolean] whether or not the POST was successful
  #
  def perform(extension_version_id)
    extension_version = ExtensionVersion.find(extension_version_id)

    uri = URI.parse(ENV['FIERI_URL'])

    data = {
      'extension_name' => extension_version.name,
      'extension_version' => extension_version.version,
      'extension_artifact_url' => extension_version.tarball.url
    }

    response = Net::HTTP.post_form(uri, data)
  end
end
