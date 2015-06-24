class ExtractExtensionVersionClassWorker
  include Sidekiq::Worker

  def perform(version_id, path)
    puts "EXTRACT CLASS: #{path}"
  end
end
