class ExtensionAuthorizer < Authorizer::Base
  #
  # Owners and collaborators of an extension can publish new versions of an extension.
  #
  def create?
    owner_or_collaborator?
  end

  #
  # Owners of an extension can destroy an extension.
  #
  def destroy?
    owner?
  end

  #
  # Owners of an extension and Supermarket admins can manage an extension.
  #
  def manage?
    owner_or_admin?
  end

  #
  # Owners of an extension are the only ones that can add collaborators.
  #
  # @return [Boolean]
  #
  def create_collaborator?
    owner?
  end

  #
  # Owners and collaborators of an extension and Supermarket admins can manage
  # the extension's urls.
  #
  # @return [Boolean]
  #
  def manage_extension_urls?
    owner_or_collaborator? || admin?
  end

  #
  # Admins can transfer ownership of an extension to another user.
  #
  # @return [Boolean]
  #
  def transfer_ownership?
    owner_or_admin?
  end

  #
  # Owners of an extension and Supermarket admins can deprecate an extension if
  # that extension is not already deprecated.
  #
  # @return [Boolean]
  #
  def deprecate?
    !record.deprecated? && owner_or_admin?
  end

  #
  # Owners of an extension and Supermarket admins can undeprecate an extension if
  # that extension is deprecated.
  #
  # @return [Boolean]
  #
  def undeprecate?
    record.deprecated? && owner_or_admin?
  end

  #
  # Owners of an extension and Supermarket admins can put an extension up for
  # adoption.
  #
  # @return [Boolean]
  #
  def manage_adoption?
    owner_or_admin?
  end

  #
  # Admins can toggle an extension as featured.
  #
  # @return [Boolean]
  #
  def toggle_featured?
    admin?
  end

  #
  # Admins can disable an extension.
  #
  # @return [Boolean]
  #
  def disable?
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
