class Extension < ActiveRecord::Base
  include PgSearch

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
    lowercase_names = Array(names).map { |name| name.to_s.downcase }

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
    against: {
      name: 'A'
    },
    associated_against: {
      github_account: { username: 'B' },
      extension_versions: { description: 'C' }
    },
    using: {
      tsearch: { dictionary: 'english', only: [:username, :description], prefix: true },
      trigram: { only: [:name] }
    },
    ranked_by: ':trigram + (0.5 * :tsearch)',
    order_within_rank: 'extensions.name'
  )

  # Callbacks
  # --------------------
  before_validation :copy_name_to_lowercase_name

  # Associations
  # --------------------
  has_many :extension_versions, dependent: :destroy
  has_many :extension_followers
  has_many :followers, through: :extension_followers, source: :user
  belongs_to :category
  belongs_to :owner, class_name: 'User', foreign_key: :user_id
  has_one :github_account, through: :owner
  belongs_to :replacement, class_name: 'Extension', foreign_key: :replacement_id
  has_many :collaborators, as: :resourceable
  has_many :collaborator_users, through: :collaborators, source: :user

  # Delegations
  # --------------------
  delegate :description, to: :latest_extension_version
  delegate :foodcritic_failure, to: :latest_extension_version
  delegate :foodcritic_feedback, to: :latest_extension_version

  # Validations
  # --------------------
  validates :name, presence: true, uniqueness: { case_sensitive: false }, format: /\A[\w_-]+\z/i
  validates :lowercase_name, presence: true, uniqueness: true
  validates :extension_versions, presence: true
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
    @sorted_extension_versions ||= extension_versions.sort_by { |v| Semverse::Version.new(v.version) }.reverse
  end

  #
  # Transfers ownership of this extension to someone else. If the user id passed
  # in represents someone that is already a collaborator on this extension, or
  # if the User initiating this transfer is an admin, then we just assign the
  # new owner and move on. If they're not already a collaborator, then we send
  # them an email asking if they want ownership of this extension. This
  # prevents abuse of people assigning random owners without getting permission.
  #
  # @param initiator [User] the User initiating the transfer
  # @param recipient [User] the User to assign ownership to
  #
  # @return [String] a key representing a message to display to the user
  #
  def transfer_ownership(initiator, recipient)
    if initiator.is?(:admin) || collaborator_users.include?(recipient)
      update_attribute(:user_id, recipient.id)

      if collaborator_users.include?(recipient)
        collaborator = collaborators.where(
          user_id: recipient.id,
          resourceable: self
        ).first
        collaborator.destroy unless collaborator.nil?
      end

      'extension.ownership_transfer.done'
    else
      transfer_request = OwnershipTransferRequest.create(
        sender: initiator,
        recipient: recipient,
        extension: self
      )
      ExtensionMailer.delay.transfer_ownership_email(transfer_request)
      'extension.ownership_transfer.email_sent'
    end
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
    latest_extension_version.supported_platforms
  end

  #
  # Returns the dependencies of the latest version of this extension.
  #
  # @return [Array<ExtensionDependency>]
  #
  def extension_dependencies
    latest_extension_version.extension_dependencies
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
    self.lowercase_name = name.to_s.downcase
  end
end
