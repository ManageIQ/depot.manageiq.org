require 'active_model/validations/chef_version_constraint_validator'

class ExtensionDependency < ActiveRecord::Base
  include SeriousErrors

  # Associations
  # --------------------
  belongs_to :extension_version
  belongs_to :extension

  # Validations
  # --------------------
  validates :name, presence: true, uniqueness: { scope: [:version_constraint, :extension_version_id] }
  validates :extension_version, presence: true
  validates :version_constraint, chef_version_constraint: true
end
