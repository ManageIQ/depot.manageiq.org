class ExtractExtensionVersionWorker
  include Sidekiq::Worker

  def perform(extension_id, tag)
    begin
      Semverse::Version.new(tag)
    rescue Semverse::InvalidVersionFormat
      return
    end

    @tag = tag
    @extension = Extension.find(extension_id)
    readme_body, readme_ext = fetch_readme
    @extension.extension_versions.create!(version: tag, readme: readme_body, readme_extension: readme_ext)
  end

  private

  def fetch_readme
    readme = octokit.readme(@extension.github_repo, ref: @tag)
    body = Base64.decode64(readme[:content])
    ext = "txt"

    if match = readme[:name].match(/\.[a-zA-Z0-9]+$/)
      ext = match[0].gsub(".", "")
    end

    return body, ext
  rescue Octokit::NotFound
    return "No readme found!", "txt"
  end

  def octokit
    @octokit ||= Rails.configuration.octokit
  end
end
