require 'authorizer/base'

class UserAuthorizer < Authorizer::Base
  #
  # Admins can make other non admin users admins.
  #
  def make_admin?
    user.is?(:admin) && !record.is?(:admin)
  end

  #
  # Admins can revoke other admin users admin role.
  #
  def revoke_admin?
    user.is?(:admin) && user != record
  end

  #
  # Admins can disable users
  #
  def disable?
    user.is?(:admin) && record.enabled?
  end

  #
  # Admins can enable users
  #
  def enable?
    user.is?(:admin) && !record.enabled?
  end
end
