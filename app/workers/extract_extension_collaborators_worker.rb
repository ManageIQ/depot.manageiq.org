class ExtractExtensionCollaboratorsWorker
  include Sidekiq::Worker

  def perform(extension_id, page = 1)
    @extension = Extension.find(extension_id)
    @contributors = octokit.contributors(@extension.github_repo, nil, page: page)

    process_contributors

    self.class.perform_async(extension_id, page + 1) if @contributors.any?
  end

  private

  def octokit
    @octokit ||= Rails.configuration.octokit
  end

  def process_contributors
    @contributors.each do |c|
      AddExtensionCollaborator.new(@extension, c[:login]).process! if c[:contributions] > 0
    end
  end
end