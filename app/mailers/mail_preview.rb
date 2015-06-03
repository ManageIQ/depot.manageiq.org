if Rails.env.development?
  class MailPreview < MailView
    def invitation_email
      InvitationMailer.invitation_email(invitation)
    end

    def ccla_signature_notification_email
      ClaSignatureMailer.ccla_signature_notification_email(ccla_signature)
    end

    def icla_signature_notification_email
      ClaSignatureMailer.icla_signature_notification_email(icla_signature)
    end

    def extension_follower_notification_email
      ExtensionMailer.follower_notification_email(
        extension.latest_extension_version,
        user
      )
    end

    def extension_deleted_notification_email
      ExtensionMailer.extension_deleted_email(extension.name, user.email)
    end

    def extension_deprecated_notification_email
      ExtensionMailer.extension_deprecated_email(extension, extension_other, user.email)
    end

    def contributor_request_email
      contributor_request = ContributorRequest.where(
        user_id: user.id,
        organization_id: organization.id,
        ccla_signature_id: ccla_signature.id
      ).first_or_create

      admin = organization.admins.first.user

      ContributorRequestMailer.incoming_request_email(admin, contributor_request)
    end

    def request_accepted_email
      contributor_request = ContributorRequest.where(
        user_id: user.id,
        organization_id: organization.id,
        ccla_signature_id: ccla_signature.id
      ).first_or_create

      ContributorRequestMailer.request_accepted_email(contributor_request)
    end

    def request_declined_email
      contributor_request = ContributorRequest.where(
        user_id: user.id,
        organization_id: organization.id,
        ccla_signature_id: ccla_signature.id
      ).first_or_create

      ContributorRequestMailer.request_declined_email(contributor_request)
    end

    def collaborator_email
      CollaboratorMailer.added_email(collaborator)
    end

    def cla_report_email
      ClaReportMailer.report_email(cla_report)
    end

    private

    def organization
      Organization.first!
    end

    def invitation
      organization.invitations.first!
    end

    def ccla_signature
      user.ccla_signatures.first!
    end

    def icla_signature
      user.icla_signatures.first!
    end

    def user
      User.where(email: 'john@example.com').first!
    end

    def extension
      Extension.first!
    end

    def extension_other
      Extension.last!
    end

    def collaborator
      Collaborator.where(user: user, resourceable: extension).first_or_create!
    end

    def cla_report
      ClaReport.generate || ClaReport.first
    end
  end
end
