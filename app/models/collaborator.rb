class Collaborator < ActiveRecord::Base # Associations
  # Associations
  # --------------------
  belongs_to :resourceable, polymorphic: true
  belongs_to :user

  # Validations
  # --------------------
  validates :resourceable, presence: true
  validates :user, presence: true
  validates :resourceable_id, uniqueness: { scope: [:user_id, :resourceable_type] }

  # Accessors
  # --------------------
  attr_accessor :user_ids

  #
  # Transfers ownership of this cookbook to this user. The existing owner is
  # automatically demoted to a collaborator.
  #
  def transfer_ownership
    transaction do
      Collaborator.create resourceable: resourceable, user: resourceable.owner
      resourceable.update_attribute(:owner, user)
      destroy
    end
  end

  #
  # Returns the ineligible users for collaboration for a given resource.
  #
  def self.ineligible_collaborators_for(resource)
    [resource.collaborator_users, resource.owner].flatten
  end

  #
  # Returns the ineligible users for ownership for a given resource.
  #
  def self.ineligible_owners_for(resource)
    [resource.owner]
  end
end
