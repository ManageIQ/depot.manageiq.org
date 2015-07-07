class NotifyModeratorsOfNewExtensionWorker
  include Sidekiq::Worker

  def perform(extension_id)
    User.moderator.all.each do |u|
      ExtensionMailer.delay.notify_moderator_of_new(extension_id, u.id)
    end
  end
end
