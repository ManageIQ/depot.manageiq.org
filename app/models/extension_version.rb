class ExtensionVersion < ActiveRecord::Base
  include SeriousErrors

  # Associations
  # --------------------
  has_many :extension_version_platforms
  has_many :supported_platforms, through: :extension_version_platforms
  has_many :extension_dependencies, dependent: :destroy
  has_many :extension_version_content_items, dependent: :destroy
  belongs_to :extension

  # Validations
  # --------------------
  validates :version, presence: true, uniqueness: { scope: :extension }
  validate :semantic_version

  # Delegations
  # --------------------
  delegate :name, :owner, to: :extension

  #
  # Returns the verison of the +ExtensionVersion+
  #
  # @example
  #   extension_version = ExtensionVersion.new(version: '1.0.2')
  #   extension_version.to_param # => '1.0.2'
  #
  # @return [String] the version of the +ExtensionVersion+
  #
  def to_param
    version
  end

  def download_url
    "https://github.com/#{extension.github_repo}/archive/#{version}.zip"
  end

  #
  # The total number of times this version has been downloaded
  #
  # @return [Fixnum]
  #
  def download_count
    web_download_count + api_download_count
  end

  # Create a link between a SupportedPlatform and a ExtensionVersion
  #
  # @param name [String] platform name
  # @param version [String] platform version
  #
  def add_supported_platform(name, version)
    platform = SupportedPlatform.for_name_and_version(name, version)
    ExtensionVersionPlatform.create! supported_platform: platform, extension_version: self
  end

  def download_daily_metric_key
    @download_daily_metric_key ||= "downloads.extension-#{extension_id}.version-#{id}"
  end

  private

  #
  # Ensure that the version string we have been given conforms to semantic
  # versioning at http://semver.org. Also accept "master".
  #
  def semantic_version
    return true if version == "master"

    begin
      Semverse::Version.new(version)
    rescue Semverse::InvalidVersionFormat
      errors.add(:version, 'is formatted incorrectly')
    end
  end
end
