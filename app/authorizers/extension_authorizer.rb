class ExtensionAuthorizer < Authorizer::Base
  #
  # Owners and collaborators of a extension can publish new versions of a extension.
  #
  def create?
    owner_or_collaborator?
  end

  #
  # Owners of a extension can destroy a extension.
  #
  def destroy?
    owner?
  end

  #
  # Owners of a extension and Supermarket admins can manage a extension.
  #
  def manage?
    owner_or_admin?
  end

  #
  # Owners of a extension are the only ones that can add collaborators.
  #
  # @return [Boolean]
  #
  def create_collaborator?
    owner?
  end

  #
  # Owners and collaborators of a extension and Supermarket admins can manage
  # the extension's urls.
  #
  # @return [Boolean]
  #
  def manage_extension_urls?
    owner_or_collaborator? || admin?
  end

  #
  # Admins can transfer ownership of a extension to another user.
  #
  # @return [Boolean]
  #
  def transfer_ownership?
    owner_or_admin?
  end

  #
  # Owners of a extension and Supermarket admins can deprecate a extension if
  # that extension is not already deprecated.
  #
  # @return [Boolean]
  #
  def deprecate?
    !record.deprecated? && owner_or_admin?
  end

  #
  # Owners of a extension and Supermarket admins can undeprecate a extension if
  # that extension is deprecated.
  #
  # @return [Boolean]
  #
  def undeprecate?
    record.deprecated? && owner_or_admin?
  end

  #
  # Owners of a extension and Supermarket admins can put a extension up for
  # adoption.
  #
  # @return [Boolean]
  #
  def manage_adoption?
    owner_or_admin?
  end

  #
  # Admins can toggle a extension as featured.
  #
  # @return [Boolean]
  #
  def toggle_featured?
    admin?
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

  def owner_or_admin?
    owner? || admin?
  end
end
