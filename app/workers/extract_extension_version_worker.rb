class ExtractExtensionVersionWorker
  include Sidekiq::Worker

  def perform(extension_id, tag, compatible_platforms)
    return if not semver?(tag)

    @tag = tag
    @extension = Extension.find(extension_id)
    @compatible_platforms = SupportedPlatform.find(compatible_platforms)

    readme_body, readme_ext = fetch_readme

    version = @extension.extension_versions.create!(
      version: tag,
      readme: readme_body,
      readme_extension: readme_ext
    )

    @compatible_platforms.each do |p|
      version.extension_version_platforms.create(supported_platform_id: p.id)
    end
  rescue ActiveRecord::RecordInvalid
  end

  private

  def semver?(tag)
    begin
      Semverse::Version.new(tag)
      return true
    rescue Semverse::InvalidVersionFormat
      return false
    end
  end

  def fetch_readme
    readme = octokit.readme(@extension.github_repo, ref: @tag)

    body = Base64.decode64(readme[:content])
    ext = extract_readme_file_extension(readme[:name]) # "txt"

    return body, ext

  rescue Octokit::NotFound
    return "No readme found!", "txt"
  end

  def octokit
    @octokit ||= @extension.octokit
  end

  def extract_readme_file_extension(filename)
    if match = filename.match(/\.[a-zA-Z0-9]+$/)
      match[0].gsub(".", "")
    else
      "txt"
    end
  end
end
