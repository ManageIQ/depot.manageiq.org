class ExtractExtensionCollaboratorsWorker
  include Sidekiq::Worker

  def perform(extension_id, page = 1, from_api = :contributors)
    @extension = Extension.find(extension_id)

    if from_api == :contributors
      @contributors = octokit.contributors(@extension.github_repo, nil, page: page)
    else
      @contributors = octokit.collaborators(@extension.github_repo, page: page)
    end

    if @contributors.any?
      process_contributors
      self.class.perform_async(extension_id, page + 1, from_api)
    elsif from_api == :contributors
      self.class.perform_async(extension_id, 1, :collaborators)
    end
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end

  def process_contributors
    @contributors.each do |c|
      ExtractExtensionCollaboratorWorker.perform_async(@extension.id, c[:login])
    end
  end
end
