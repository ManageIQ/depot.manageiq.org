class ExtensionVersionPlatform < ActiveRecord::Base
  # Associations
  # --------------------
  belongs_to :extension_version
  belongs_to :supported_platform

  # Validations
  # --------------------
  validates :extension_version, presence: true
  validates :supported_platform, presence: true
end
