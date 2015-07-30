class Extension < ActiveRecord::Base
  include PgSearch

  default_scope { where(enabled: true) }

  #
  # Query extensions by case-insensitive name.
  #
  # @param name [String, Array<String>] a single name, or a collection of names
  #
  # @example
  #   Extension.with_name('redis').first
  #     #<Extension name: "redis"...>
  #   Extension.with_name(['redis', 'apache2']).to_a
  #     [#<Extension name: "redis"...>, #<Extension name: "apache2"...>]
  #
  # @todo: query and index by +LOWER(name)+ when ruby schema dumps support such
  #   a thing.
  #
  scope :with_name, lambda { |names|
    lowercase_names = Array(names).map { |name| name.to_s.downcase.parameterize }

    where(lowercase_name: lowercase_names)
  }

  scope :ordered_by, lambda { |ordering|
    reorder({
      'recently_updated' => 'updated_at DESC',
      'recently_added' => 'id DESC',
      'most_downloaded' => '(web_download_count + api_download_count) DESC, id ASC',
      'most_followed' => 'extension_followers_count DESC, id ASC'
    }.fetch(ordering, 'name ASC'))
  }

  scope :owned_by, lambda { |username|
    joins(owner: :github_account).where('accounts.username = ?', username)
  }

  scope :supported_platforms, lambda { |sp_ids|
    joins(:all_supported_platforms).where('supported_platforms.id IN (?)', sp_ids)
  }

  scope :index, lambda { |opts = {}|
    includes(:extension_versions, owner: :github_account)
    .ordered_by(opts.fetch(:order, 'name ASC'))
    .limit(opts.fetch(:limit, 10))
    .offset(opts.fetch(:start, 0))
  }

  scope :featured, -> { where(featured: true) }

  # Search
  # --------------------
  pg_search_scope(
    :search,
    against: [:name],
    associated_against: {
      tags: [:name],
      github_account: [:username],
      extension_versions: [:description]
    }
  )

  # Callbacks
  # --------------------
  before_validation :copy_name_to_lowercase_name
  before_validation :normalize_github_url
  before_save :update_tags

  # Associations
  # --------------------
  has_many :extension_versions, dependent: :destroy
  has_many :extension_followers
  has_many :followers, through: :extension_followers, source: :user
  belongs_to :category
  belongs_to :owner, class_name: 'User', foreign_key: :user_id
  has_one :github_account, through: :owner
  belongs_to :replacement, class_name: 'Extension', foreign_key: :replacement_id
  has_many :collaborators, as: :resourceable, dependent: :destroy
  has_many :collaborator_users, through: :collaborators, source: :user

  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings

  has_many :all_supported_platforms, through: :extension_versions, class: SupportedPlatform, source: :supported_platforms

  # Delegations
  # --------------------
  delegate :foodcritic_failure, to: :latest_extension_version, allow_nil: true
  delegate :foodcritic_feedback, to: :latest_extension_version, allow_nil: true

  # Validations
  # --------------------
  validates :name, presence: true, uniqueness: { case_sensitive: false }, format: /\A[\w\s_-]+\z/i
  validates :lowercase_name, presence: true, uniqueness: true
  # validates :extension_versions, presence: true
  validates :source_url, url: {
    allow_blank: true,
    allow_nil: true
  }
  validates :issues_url, url: {
    allow_blank: true,
    allow_nil: true
  }
  validates :replacement, presence: true, if: :deprecated?

  #
  # The total number of times an extension has been downloaded from Supermarket
  #
  # @return [Fixnum]
  #
  def self.total_download_count
    sum(:api_download_count) + sum(:web_download_count)
  end

  #
  # Sorts extension versions according to their semantic version
  #
  # @return [Array<ExtensionVersion>] the sorted ExtensionVersion records
  #
  def sorted_extension_versions
    @sorted_extension_versions ||= extension_versions.
      reject { |v| v.version == "master" }.
      sort_by { |v| Semverse::Version.new(v.version) }.
      reverse.
      concat(extension_versions.select { |v| v.version == "master" })
  end

  #
  # Form placeholder.
  # @return [String]
  #
  attr_accessor :tag_tokens
  attr_accessor :github_url_short

  def tag_tokens
    @tag_tokens ||= tags.map(&:name).join(", ")
  end

  #
  # Form placeholder.
  # @return [Array]
  #
  attr_accessor :compatible_platforms

  #
  # Returns an array of users to whom this extension can be transferred.
  #
  # @return [Array] array of users who may receive ownership
  #
  def transferrable_to_users
    collaborator_users.where.not(id: user_id)
  end

  #
  # Transfers ownership of this extension to someone else.
  #
  # @param initiator [User] the User initiating the transfer
  # @param recipient [User] the User to assign ownership to
  #
  # @return [String] a key representing a message to display to the user
  #
  def transfer_ownership(recipient)
    update_attribute(:user_id, recipient.id)
    'extension.ownership_transfer.done'
  end

  #
  # The most recent ExtensionVersion, based on the semantic version number
  #
  # @return [ExtensionVersion] the most recent ExtensionVersion
  #
  def latest_extension_version
    @latest_extension_version ||= sorted_extension_versions.first
  end

  #
  # Return all of the extension errors as well as full error messages for any of
  # the ExtensionVersions
  #
  # @return [Array<String>] all the error messages
  #
  def seriously_all_of_the_errors
    messages = errors.full_messages.reject { |e| e == 'Extension version is invalid' }

    extension_versions.each do |version|
      almost_everything = version.errors.full_messages.reject { |x| x =~ /Tarball can not be/ }
      messages += almost_everything
    end

    messages
  end

  #
  # Returns the name of the +Extension+ parameterized.
  #
  # @return [String] the name of the +Extension+ parameterized
  #
  def to_param
    name.parameterize
  end

  #
  # Return the specified +ExtensionVersion+. Raises an
  # +ActiveRecord::RecordNotFound+ if the version does not exist. Versions can
  # be specified with either underscores or dots.
  #
  # @example
  #   extension.get_version!("1_0_0")
  #   extension.get_version!("1.0.0")
  #   extension.get_version!("latest")
  #
  # @param version [String] the version of the Extension to find. Pass in
  #                         'latest' to return the latest version of the
  #                         extension.
  #
  # @return [ExtensionVersion] the +ExtensionVersion+ with the version specified
  #
  def get_version!(version)
    version.gsub!('_', '.')

    if version == 'latest'
      latest_extension_version
    else
      extension_versions.find_by!(version: version)
    end
  end

  #
  # Saves a new version of the extension as specified by the given metadata, tarball
  # and readme. If it's a new extension the user specified becomes the owner.
  #
  # @raise [ActiveRecord::RecordInvalid] if the new version fails validation
  # @raise [ActiveRecord::RecordNotUnique] if the new version is a duplicate of
  #   an existing version for this extension
  #
  # @return [ExtensionVersion] the Extension Version that was published
  #
  # @param params [ExtensionUpload::Parameters] the upload parameters
  #
  def publish_version!(params)
    metadata = params.metadata

    if metadata.privacy &&
        ENV['ENFORCE_PRIVACY'].present? &&
        ENV['ENFORCE_PRIVACY'] == 'true'
      errors.add(:base, I18n.t('api.error_messages.privacy_violation'))
      raise ActiveRecord::RecordInvalid.new(self)
    end

    tarball = params.tarball
    readme = params.readme
    changelog = params.changelog

    dependency_names = metadata.dependencies.keys
    existing_extensions = Extension.with_name(dependency_names)

    extension_version = nil

    transaction do
      extension_version = extension_versions.build(
        extension: self,
        description: metadata.description,
        license: metadata.license,
        version: metadata.version,
        tarball: tarball,
        readme: readme.contents,
        readme_extension: readme.extension,
        changelog: changelog.contents,
        changelog_extension: changelog.extension
      )

      self.updated_at = Time.now

      [:source_url, :issues_url].each do |url|
        url_val = metadata.send(url)

        if url_val.present?
          write_attribute(url, url_val)
        end
      end

      self.privacy = metadata.privacy
      save!

      metadata.platforms.each do |name, version_constraint|
        extension_version.add_supported_platform(name, version_constraint)
      end

      metadata.dependencies.each do |name, version_constraint|
        extension_version.extension_dependencies.create!(
          name: name,
          version_constraint: version_constraint,
          extension: existing_extensions.find { |c| c.name == name }
        )
      end
    end

    extension_version
  end

  #
  # Returns true if the user passed follows the extension.
  #
  # @return [TrueClass]
  #
  # @param user [User]
  #
  def followed_by?(user)
    extension_followers.where(user: user).any?
  end

  #
  # Returns the platforms supported by the latest version of this extension.
  #
  # @return [Array<SupportedVersion>]
  #
  def supported_platforms
    latest_extension_version.try(:supported_platforms) || []
  end

  #
  # Returns the dependencies of the latest version of this extension.
  #
  # @return [Array<ExtensionDependency>]
  #
  def extension_dependencies
    latest_extension_version.try(:extension_dependencies) || []
  end

  #
  # Returns all of the ExtensionDependency records that are contingent upon this one.
  #
  # @return [Array<ExtensionDependency>]
  #
  def contingents
    ExtensionDependency.includes(extension_version: :extension)
      .where(extension_id: id)
      .sort_by do |cd|
        [
          cd.extension_version.extension.name,
          Semverse::Version.new(cd.extension_version.version)
        ]
      end
  end

  #
  # The username of this extension's owner
  #
  # @return [String]
  #
  def maintainer
    owner.username
  end

  #
  # The total number of times this extension has been downloaded
  #
  # @return [Fixnum]
  #
  def download_count
    web_download_count + api_download_count
  end

  #
  # Sets the extension's deprecated attribute to true, assigns the replacement
  # extension if specified and saves the extension.
  #
  # An extension can only be replaced with an extension that is not deprecated.
  #
  # @param replacement_extension [Extension] the extension to succeed this extension
  #   once deprecated
  #
  # @return [Boolean] whether or not the extension was successfully deprecated
  #   and  saved
  #
  def deprecate(replacement_extension)
    if replacement_extension.deprecated?
      errors.add(:base, I18n.t('extension.deprecate_with_deprecated_failure'))
      return false
    else
      self.deprecated = true
      self.replacement = replacement_extension
      save
    end
  end

  #
  # Searches for extensions based on the +query+ parameter. Returns results that
  # are elgible for deprecation (not deprecated and not this extension).
  #
  # @param query [String] the search term
  #
  # @return [Array<Extension> the +Extension+ search results
  #
  def deprecate_search(query)
    Extension.search(query).where(deprecated: false).where.not(id: id)
  end

  #
  # Returns the username/repo formatted name of the GitHub repo.
  #
  # @return [String]
  #
  def github_repo
    self.github_url.gsub("https://github.com/", "")
  end

  #
  # Returns the file system path where the repo is stored for syncing.
  #
  # @return [String]
  #
  def repo_path
    @repo_path ||= "/tmp/extension-repo-#{id}"
  end

  #
  # Returns an Octokit client configured for the Extension's owner.
  #
  # @return [Ocotkit::Client]
  #
  def octokit
    @octokit ||= Octokit::Client.new(
      access_token: owner.github_account.oauth_token,
      client_id: Rails.configuration.octokit.client_id,
      client_secret: Rails.configuration.octokit.client_secret
    )
  end

  private

  #
  # Populates the +lowercase_name+ attribute with the lowercase +name+
  #
  # This exists until Rails schema dumping supports Posgres's expression
  # indices, which would allow us to create an index on LOWER(name). To do that
  # now, we'd have to use the raw SQL schema dumping functionality, which is
  # less-than ideal
  #
  def copy_name_to_lowercase_name
    self.lowercase_name = name.to_s.downcase.parameterize
  end

  #
  # Normalizes the GitHub URL to a standard format.
  #
  def normalize_github_url
    url = self.github_url || ""
    url.gsub!(/(https?:\/\/)?(www\.)?github\.com\//, "")
    self.github_url = "https://github.com/#{url}"
    true
  end

  def update_tags
    self.tags = self.tag_tokens.split(",").map(&:downcase).map do |token|
      Tag.where(name: token).first_or_create
    end
    self.tag_list = self.tag_tokens
    true
  end
end
