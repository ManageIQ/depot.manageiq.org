require 'virtus'

class ExtensionUpload
  #
  # Acts as a schema for an extension's metadata.json. It only provides fields
  # for the metadata attributes we use, while remaining flexible enough to
  # handle any metadata hash.
  #
  # @note It is a value object which means that two +Metadata+ objects are
  #   considered to be identical if they have the same attribute values
  #
  # @example
  #   metadata = ExtensionUpload::Metadata.new(name: "Apache")
  #   metadata.name #=> "Apache"
  #
  class Metadata
    include Virtus.value_object(strict: true)

    #
    # @!attribute [r] name
    #   @return [String] The extension name
    #

    #
    # @!attribute [r] version
    #   @return [String] The extension version
    #

    #
    # @!attribute [r] description
    #   @return [String] The extension description
    #

    #
    # @!attribute [r] license
    #   @return [String] The extension license
    #

    #
    # @!attribute [r] platforms
    #   @return [Hash<String,String>] The platforms supported by the extension
    #
    #   @example
    #     metadata.platforms == { 'ubuntu' => '>= 0.0.0' }
    #

    #
    # @!attribute [r] dependencies
    #   @return [Hash<String,String>] The extension dependencies
    #
    #   @example
    #     metadata.dependencies == { 'apt' => '~> 0.0.2' }
    #

    #
    # @!attribute [r] source_url
    #   @return [String] The extension source url
    #

    #
    # @!attribute [r] issues_url
    #   @return [String] The extension issues url
    #

    #
    # @!attribute [r] privacy
    #   @return [Boolean] Whether or not this extension is private
    #

    values do
      attribute :name, String, default: ''
      attribute :version, String, default: ''
      attribute :description, String, default: ''
      attribute :license, String, default: ''
      attribute :platforms, Hash[String => String]
      attribute :dependencies, Hash[String => String]
      attribute :source_url, String, default: ''
      attribute :issues_url, String, default: ''
      attribute :privacy, Boolean, default: false
    end
  end
end
