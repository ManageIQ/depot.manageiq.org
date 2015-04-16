class OwnershipTransferRequest < ActiveRecord::Base
  include Tokenable

  # Associations
  # --------------------
  belongs_to :cookbook
  belongs_to :recipient, class_name: 'User'
  belongs_to :sender, class_name: 'User'

  # Validations
  # --------------------
  validates :token, presence: true, uniqueness: true
  validates :cookbook, presence: true
  validates :recipient, presence: true
  validates :sender, presence: true

  # Callbacks
  # --------------------
  before_validation { generate_token }

  #
  # Accept this transfer request. This will mark this request as accepted, and
  # update the cookbook in question to have the new owner.
  #
  # Note that this method will not do anything if this request has already been
  # responded to.
  #
  def accept!
    return unless accepted.nil?
    update_attribute(:accepted, true)
    cookbook.update_attribute(:user_id, recipient.id)
  end

  #
  # Decline this transfer request. This will mark this request as declined, and
  # do nothing else.
  #
  # Note that this method will not do anything if this request has already been
  # responded to.
  #
  def decline!
    return unless accepted.nil?
    update_attribute(:accepted, false)
  end

  def to_param
    token
  end
end
