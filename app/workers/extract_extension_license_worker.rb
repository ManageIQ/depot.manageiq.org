class ExtractExtensionLicenseWorker
  include Sidekiq::Worker

  def perform(extension_id)
    @extension = Extension.find(extension_id)

    @repo = octokit.repo(@extension.github_repo, accept: "application/vnd.github.drax-preview+json")

    if @repo[:license]
      begin
        license = octokit.license(@repo[:license][:key], accept: "application/vnd.github.drax-preview+json")
      rescue Octokit::NotFound
        license = {
          name: @repo[:license][:name],
          body: ""
        }
      end

      @extension.update_attributes(
        license_name: license[:name],
        license_text: license[:body]
      )
    end
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end
