class CollectExtensionMetadataWorker
  include Sidekiq::Worker

  def perform(extension_id)
    ExtractExtensionLicenseWorker.perform_async(extension_id)
    ExtractExtensionVersionsWorker.perform_async(extension_id)
    ExtractExtensionCollaboratorsWorker.perform_async(extension_id)
  end
end
