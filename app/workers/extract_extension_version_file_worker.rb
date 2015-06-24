class ExtractExtensionVersionFileWorker
  include Sidekiq::Worker

  def perform(version_id, path)
    puts "EXTRACT FILE: #{path}"
  end
end
