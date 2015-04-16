class ClaSignatureMailer < ActionMailer::Base
  layout 'mailer'

  #
  # Creates CCLA signature notification email
  #
  # @param ccla_signature [CclaSignature] the signature
  #
  def ccla_signature_notification_email(ccla_signature)
    @ccla_signature = ccla_signature
    @to = ENV['CLA_SIGNATURE_NOTIFICATION_EMAIL']

    mail(to: @to, subject: "New CCLA signed by #{@ccla_signature.company}")
  end

  #
  # Creates ICLA signature notification email
  #
  # @param icla_signature [IclaSignature] the signature
  #
  def icla_signature_notification_email(icla_signature)
    @icla_signature = icla_signature
    @to = ENV['CLA_SIGNATURE_NOTIFICATION_EMAIL']
    username = @icla_signature.user.username

    mail(to: @to, subject: "New ICLA signed by #{username}")
  end
end
