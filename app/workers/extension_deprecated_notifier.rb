#
# Lets those who follow and/or collaborate on an extension know when the extension
# has been deprecated.
#
class ExtensionDeprecatedNotifier
  include Sidekiq::Worker

  #
  # Queues an email to each follower and/or collaborator of the extension
  #
  # @param extension_id [Fixnum] Identifies a +Extension+
  #
  def perform(extension_id)
    extension = Extension.find(extension_id)
    replacement_extension = extension.replacement

    users_to_email(extension).each do |user|
      ExtensionMailer.extension_deprecated_email(
        extension,
        replacement_extension,
        user
      ).deliver
    end
  end

  private

  def users_to_email(extension)
    subscribed_user_ids = SystemEmail.find_by!(name: 'Extension deprecated').
      subscribed_users.
      pluck(:id)

    users_to_email = []
    users_to_email << extension.owner
    users_to_email << extension.collaborator_users.where(id: subscribed_user_ids)
    users_to_email << extension.followers.where(id: subscribed_user_ids)

    users_to_email.flatten.uniq
  end
end
