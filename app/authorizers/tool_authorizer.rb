class ToolAuthorizer < Authorizer::Base
  #
  # Owners of a tool and Supermarket admins can edit it.
  #
  # @return [Boolean]
  #
  def edit?
    owner_or_collaborator? || admin?
  end

  #
  # Owners of a tool and Supermarket admins can update it.
  #
  # @return [Boolean]
  #
  def update?
    owner_or_collaborator? || admin?
  end

  #
  # Owners of a tool and Supermarket admins can delete it.
  #
  # @return [Boolean]
  #
  def destroy?
    owner? || admin?
  end

  #
  # Owners of an extension, collaborators of an extension and Supermarket admins can
  # manage an extension.
  #
  def manage?
    owner_or_collaborator? || admin?
  end

  #
  # Owners of a tool and Supermarket admins can add collaborators.
  #
  def create_collaborator?
    owner?
  end

  #
  # Owners of a tool and Supermarket admins can put an extension up for
  # adoption.
  #
  # @return [Boolean]
  #
  def manage_adoption?
    owner? || admin?
  end

  private

  def admin?
    user.is?(:admin)
  end

  def owner?
    record.owner == user
  end

  def owner_or_collaborator?
    owner? || record.collaborator_users.include?(user)
  end
end
