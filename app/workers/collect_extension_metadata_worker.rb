class CollectExtensionMetadataWorker
  include Sidekiq::Worker

  def perform(extension_id, compatible_platforms = [])
    ExtractExtensionBasicMetadataWorker.new.perform(extension_id)
    ExtractExtensionLicenseWorker.perform_async(extension_id)
    ExtractExtensionCollaboratorsWorker.perform_async(extension_id)
    ExtractExtensionStargazersWorker.perform_async(extension_id)

    SyncExtensionRepoWorker.perform_async(extension_id, compatible_platforms)
  end
end
