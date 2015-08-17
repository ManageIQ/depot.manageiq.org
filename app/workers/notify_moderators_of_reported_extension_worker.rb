class NotifyModeratorsOfReportedExtensionWorker
  include Sidekiq::Worker

  def perform(extension_id, report_description, reported_by_id)
    User.moderator.all.each do |u|
      ExtensionMailer.delay.notify_moderator_of_reported(extension_id, u.id, report_description, reported_by_id)
    end
  end
end
