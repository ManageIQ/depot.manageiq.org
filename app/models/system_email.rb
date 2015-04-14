class SystemEmail < ActiveRecord::Base
  # Associations
  # --------------------
  has_many :email_preferences
  has_many :subscribed_users, through: :email_preferences, source: :user

  # Validations
  # --------------------
  validates :name, presence: true, uniqueness: true
end
