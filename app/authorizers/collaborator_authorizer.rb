class CollaboratorAuthorizer < Authorizer::Base
  #
  # Owners of an extension are the only ones that can transfer ownership and they
  # can only transfer it to someone that's already a collaborator on
  # an extension.
  #
  # @return [Boolean]
  #
  def transfer?
    record.resourceable.owner == user && record.persisted?
  end

  #
  # Owners of an extension are the only ones that can add collaborators.
  #
  # @return [Boolean]
  #
  def create?
    record.resourceable.owner == user
  end

  #
  # If you're an owner of an extension, you can remove any collaborator. If you
  # are a collaborator, then you should be able to remove yourself, but no one
  # else.
  #
  # @return [Boolean]
  #
  def destroy?
    create? || record.user == user
  end
end
