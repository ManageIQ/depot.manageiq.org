class PollExtensionReposWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { daily }

  def perform
    Extension.where("updated_at < ?", Time.now - 24.hours).pluck(:id).each do |eid|
      CollectExtensionMetadataWorker.perform_async(eid)
    end
  end
end
