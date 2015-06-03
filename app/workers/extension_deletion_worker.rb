class ExtensionDeletionWorker
  include Sidekiq::Worker

  #
  # Notify anyone that was a follower or a collaborator on this extension that
  # it has been deleted. This will only email users with email notifications
  # turned on.
  #
  # @param [Hash] extension a hash representation of the extension to delete
  #
  def perform(extension)
    id = extension['id']

    subscribed_user_ids = SystemEmail.find_by!(name: 'Extension deleted').
      subscribed_users.
      pluck(:id)

    followers_or_collaborators = ExtensionFollower.where(
      extension_id: id
    ).includes(:user) +
      Collaborator.where(
        resourceable_id: id,
        resourceable_type: 'Extension'
    ).includes(:user)

    users = followers_or_collaborators.map(&:user).uniq.select { |u| subscribed_user_ids.include?(u.id) }

    users.each do |user|
      ExtensionMailer.extension_deleted_email(extension['name'], user).deliver
    end

    followers_or_collaborators.each(&:destroy)
  end
end
