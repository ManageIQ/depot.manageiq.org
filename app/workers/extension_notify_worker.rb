class ExtensionNotifyWorker
  include Sidekiq::Worker

  #
  # Notify all followers that a new version of the specified +Extension+ has been updated.
  # This will only email the follower if the user has email notifications turned on.
  # This will not email users with an OCID oauth token of 'imported' to prevent migrated users
  # from being sent emails until they have logged into Supermarket.
  #
  # @param [Integer] extension_version_id the id of ExtensionVersion that was updated
  #
  def perform(extension_version_id)
    extension_version = ExtensionVersion.find(extension_version_id)

    active_user_ids = User.joins(:accounts).
      where('provider = ? AND oauth_token != ?', 'chef_oauth2', 'imported').
      pluck(:id)

    subscribed_user_ids = SystemEmail.find_by!(name: 'New extension version').
      subscribed_users.
      pluck(:id)

    common_user_ids = active_user_ids & subscribed_user_ids
    return if common_user_ids.blank?

    emailable_extension_followers = extension_version.
      extension.
      extension_followers.
      joins(:user).
      where(users: { id: common_user_ids })

    emailable_extension_followers.each do |extension_follower|
      ExtensionMailer.follower_notification_email(extension_version, extension_follower.user).deliver
    end
  end
end
