class ExtensionMailer < ActionMailer::Base
  layout 'mailer'
  add_template_helper(ExtensionVersionsHelper)

  #
  # Creates an email to a user that is an extension follower
  # that notifies them a new extension version has been published
  #
  # @param extension_version [ExtensionVersion] the extension version that was
  # published
  # @param user [User] the user to notify
  #
  def follower_notification_email(extension_version, user)
    @extension_version = extension_version
    @email_preference = user.email_preference_for('New extension version')
    @to = user.email

    mail(to: @to, subject: "A new version of the #{@extension_version.name} extension has been released")
  end

  #
  # Create notification email to an extension's collaborators and followers
  # explaining that the extension has been deleted
  #
  # @param name [String] the name of the extension
  # @param user [User] the user to notify
  #
  def extension_deleted_email(name, user)
    @name = name
    @email_preference = user.email_preference_for('Extension deleted')
    @to = user.email

    mail(to: @to, subject: "The #{name} extension has been deleted")
  end

  #
  # Sends notification email to an extension's collaborators and followers
  # explaining that the extension has been deprecated in favor of another
  # extension
  #
  # @param extension [Extension] the extension
  # @param replacement_extension [Extension] the replacement extension
  # @param user [User] the user to notify
  #
  def extension_deprecated_email(extension, replacement_extension, user)
    @extension = extension
    @replacement_extension = replacement_extension
    @email_preference = user.email_preference_for('Extension deprecated')
    @to = user.email

    subject = %(
      The #{@extension.name} extension has been deprecated in favor
      of the #{@replacement_extension.name} extension
    ).squish

    mail(to: @to, subject: subject)
  end

  #
  # Sends email to the recipient of an OwnershipTransferRequest, asking if they
  # want to become the new owner of an Extension. This is generated when
  # an Extension owner initiates a transfer of ownership to someone that's not
  # currently a Collaborator on the Extension.
  #
  # @param transfer_request [OwnershipTransferRequest]
  #
  def transfer_ownership_email(transfer_request)
    @transfer_request = transfer_request
    @sender = transfer_request.sender.name
    @extension = transfer_request.extension.name

    subject = %(
      #{@sender} wants to transfer ownership of the #{@extension} extension to
      you.
    ).squish

    mail(to: transfer_request.recipient.email, subject: subject)
  end

  #
  # Sends an email to the given moderator notifying them that an extension has
  # just been added.
  #
  # @param extension_id (Fixnum)
  # @param user_id (Fixnum)
  #
  def notify_moderator_of_new(extension_id, user_id)
    @extension = Extension.find(extension_id)
    @moderator = User.find(user_id)

    @subject = %(New extension "#{@extension.name}" awaiting moderation)

    mail(to: @moderator.email, subject: @subject)
  end

  #
  # Sends an email to the given moderator notifying them that an extension has
  # just been reported.
  #
  # @param extension_id (Fixnum)
  # @param user_id (Fixnum)
  #
  def notify_moderator_of_reported(extension_id, user_id)
    @extension = Extension.find(extension_id)
    @moderator = User.find(user_id)

    @subject = %(Extension "#{@extension.name}" reported)

    mail(to: @moderator.email, subject: @subject)
  end
end
