class SupportedPlatform < ActiveRecord::Base
  include SeriousErrors

  # Associations
  # --------------------
  has_many :extension_version_platforms
  has_many :extension_versions, through: :extension_version_platforms

  # Validations
  # --------------------
  validates :name, presence: true
  validates :released_on, presence: true
end
