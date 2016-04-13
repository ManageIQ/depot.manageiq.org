class ExtractExtensionVersionWorker
  include Sidekiq::Worker

  def perform(extension_id, tag, compatible_platforms)
    return if not semver?(tag)

    @tag = tag
    @extension = Extension.find(extension_id)
    @compatible_platforms = SupportedPlatform.find(compatible_platforms)

    readme_body, readme_ext = fetch_readme

    version = @extension.extension_versions.first_or_create(version: tag)

    version.update_attributes(
      readme: readme_body,
      readme_extension: readme_ext,
      yml_line_count: 0,
      rb_line_count: 0
    )

    @compatible_platforms.each do |p|
      version.extension_version_platforms.first_or_create(supported_platform_id: p.id)
    end

    ExtractExtensionVersionContentsWorker.perform_async(version.id)
    ExtractExtensionVersionLastCommitWorker.perform_async(version.id)
  end

  private

  def semver?(tag)
    return true if tag == "master"

    begin
      Semverse::Version.new(tag.gsub(/\Av/, ""))
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
    return "There is no README file for this extension.", "txt"
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
