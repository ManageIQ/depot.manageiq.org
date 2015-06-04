class ExtensionVersion < ActiveRecord::Base
  include SeriousErrors

  # Associations
  # --------------------
  has_many :extension_version_platforms
  has_many :supported_platforms, through: :extension_version_platforms
  has_many :extension_dependencies, dependent: :destroy
  belongs_to :extension

  # Attachments
  # --------------------
  has_attached_file :tarball

  # Validations
  # --------------------
  validates :readme, presence: true
  validates :version, presence: true, uniqueness: { scope: :extension }
  validate :semantic_version
  validates_attachment(
    :tarball,
    content_type: {
      content_type: ['application/x-gzip', 'application/gzip',
                     'application/octet-stream', 'application/x-tar',
                     'application/x-compressed-tar', 'application/x-gtar',
                     'application/x-bzip2', 'application/gzipped-tar',
                     'application/x-compressed', 'application/download',
                     'application/x-gtar-compressed', 'application/zip',
                     'application/x-bzip', 'application/x-zip-compressed',
                     'application/cap', 'application/x-tar-gz',
                     'application/postscript', 'application/x-targz'],
      message: ->(_, info) { "can not be #{info[:value]}." }
    }
  )

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

  private

  #
  # Ensure that the version string we have been given conforms to semantic
  # versioning at http://semver.org
  #
  def semantic_version
    begin
      Semverse::Version.new(version)
    rescue Semverse::InvalidVersionFormat
      errors.add(:version, 'is formatted incorrectly')
    end
  end
end
