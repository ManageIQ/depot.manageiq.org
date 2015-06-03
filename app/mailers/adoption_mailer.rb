class AdoptionMailer < ActionMailer::Base
  layout 'mailer'

  #
  # Sends an email to the owner of a extension, letting them know that
  # someone is interested in taking over ownership.
  #
  # @param extension_or_tool [Extension]
  # @param user [User] the interested user
  #
  def interest_email(extension, user)
    @name = extension.name
    @email = user.email
    @to = extension.owner.email
    @thing = extension.class.name.downcase

    mail(to: @to, subject: "Interest in adopting your #{@name} #{@thing}")
  end
end
