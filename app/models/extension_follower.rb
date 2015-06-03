class ExtensionFollower < ActiveRecord::Base
  # Associations
  # --------------------
  belongs_to :extension, counter_cache: true
  belongs_to :user

  # Validations
  # --------------------
  validates :extension, presence: true
  validates :user, presence: true
  validates :extension_id, uniqueness: { scope: :user_id }
end
